# claude_link

One-way context sync for Claude projects. A thread pushes markdown notes to a
private GitHub repo; a scheduled PowerShell pull mirrors them onto your PC, so
the next thread — browser, desktop, wherever — starts with the context the last
one left.

    Claude thread  ->  private data repo  ->  your PC

The repo is authoritative: files not in it get wiped locally.

| Where | Holds | Visibility |
|---|---|---|
| this repo | `pull-context.ps1`, and the protocol threads follow | public |
| your data repo | `contexts/<project>/`, nothing else | private |
| sync folder on your PC | the script, `pat.txt`, `sync-config.psd1`, the log | never leaves the machine |

The split is the point: public code that says nothing about you, private data,
and the token plus machine-specific paths staying on the machine that needs
them. No repo holds a token.

## If you are forking this

The script self-updates from `$engineUrl` at the top of `pull-context.ps1`,
which points at **this** repo. Taken as-is, your copy keeps pulling my script
onto your machine forever — quietly overwriting your changes and running
whatever I push. Edit `$engineUrl` to your own fork before you run anything,
and fetch from your fork in step 3. The `dukepeet/claude_link` in the step 6
stub only decides which README your threads read, so it is harmless either way.

## Setup

**1. Create a private data repo**, initialized with a README so it has a
default branch. It holds only `contexts/<project>/` folders.

**2. Create a fine-grained PAT** scoped to that repo, Repository permissions →
**Contents: read**. Read is enough: the PC only pulls. Your threads push
through their own GitHub connection, not this token.

**3. Bootstrap the PC.** One line at a time in PowerShell. Replace
`C:\claude-sync` with wherever you want the sync folder, and
`dukepeet/claude_link` with your fork.

    New-Item -ItemType Directory -Force C:\claude-sync | Out-Null; "PASTE_PAT" | Set-Content C:\claude-sync\pat.txt

    Invoke-WebRequest "https://raw.githubusercontent.com/dukepeet/claude_link/main/pull-context.ps1" -OutFile C:\claude-sync\pull-context.ps1

    Invoke-WebRequest "https://raw.githubusercontent.com/dukepeet/claude_link/main/sync-config.example.psd1" -OutFile C:\claude-sync\sync-config.psd1

    schtasks /create /tn "Claude context pull" /tr "powershell -NoProfile -ExecutionPolicy Bypass -w hidden -f C:\claude-sync\pull-context.ps1" /sc onlogon /f

    $d = [Environment]::GetFolderPath("Desktop"); $s = (New-Object -ComObject WScript.Shell).CreateShortcut("$d\Pull context.lnk"); $s.TargetPath = "powershell.exe"; $s.Arguments = "-NoProfile -ExecutionPolicy Bypass -f C:\claude-sync\pull-context.ps1 -wait"; $s.Save()

**4. Edit `sync-config.psd1`.** Set `repo` to your data repo, and add a `map`
entry per project: the folder name under `contexts/`, and where it lands
locally.

**5. Run it** from the desktop shortcut. A healthy run prints each project and
`OK`.

Nothing needs re-fetching after this. The script self-updates on every pull, so
pushing a change here is the whole deployment.

**6. Point each Claude project at its folder**, in the project's instructions:

    Context project: myproject (contexts/myproject/ in you/your-context-data).
    Requires the GitHub connector. If its tools are missing, enable it for
    this conversation.
    Before any context file work, read README.md from dukepeet/claude_link
    and follow it.

The stub has to name the connector, because the README it points at is
unreadable until the connector works.

## Protocol for Claude threads

This section governs the data repo. Your project's folder is
`contexts/<project>/`, named in the project instructions.

**Stay in your folder.** Never add, edit, or delete anything outside it on your
own initiative — another project's folder, or the repo root — even to correct
something that looks stale. Report it, name the thread that owns it, and offer
to write a handoff instead of doing the work. If the user tells you to do it
here anyway, do it — but make the offer first, every time. Approval is not the
test at this boundary; ownership is. "May I?" invites yes, and a thread that
keeps asking absorbs another thread's work one approval at a time.

**Fetch before every push.** `push_files` overwrites whatever is on `main`. No
branches, no PRs, so nothing surfaces a conflict and nothing stops you silently
clobbering what another thread pushed while your thread was thinking. Project
knowledge and anything you read earlier in the thread may already be stale.

**Push immediately.** Every time you write or substantially rewrite a context
file, push it in the same turn — do not wait for the user to say "dump".
"dump" stays valid as a manual catch-up for anything missed.

1. List `contexts/<project>/` and its `handoffs/` before your first push. Reuse
   existing filenames exactly; never invent a variant of a name already there.
   Mention any handoffs you find — you cannot tell which are addressed to you,
   so let the user say.
2. Re-fetch every existing file you are about to overwrite, in the same turn as
   the push. A copy you read earlier in the thread does not count.
3. Push full final content. Holding only part of a file, say so and skip it.
4. Use `push_files` — one commit, no blob SHA needed for overwrites. Message:
   `context dump <date>`.
5. Never create branches or PRs. Never delete files, except an actioned handoff
   addressed to you.
6. Reply with paths written, flagging any that already existed.

Never put credentials, tokens, or machine-specific paths in the data repo.
Those live in the sync folder on the PC, which no repo can see.

Filenames: kebab-case slugs, `.md`.

### Handoffs

A note from one thread to another in the same project, living in
`contexts/<project>/handoffs/`. It is how work that belongs elsewhere moves
without the raising thread doing it.

- Filename is `<owner>--<subject>.md`. The owner is the recipient, since the
  folder narrows to a project and not to a thread; the sender goes in the body.
- Create, do not edit. A handoff you did not write is not yours to rewrite —
  raise a new one instead. Create-only means there is no way to clobber
  someone else's.
- Delete it once actioned. Git keeps the history.
- The owner name should read as a topic, so a thread that does not exist yet
  can still be the recipient.

### Writing straight to the PC

If the thread can reach a project's local folder, write the same final content
there too, immediately after pushing — it saves waiting for the next pull.

This is **best effort**. Content identical to the repo makes the next `/MIR` a
no-op, and if a pull wipes it anyway nothing is lost, because the repo already
has it. So: only ever write content that has already been pushed, never treat
the local write as a substitute for the push, and if the folder isn't
reachable, skip it silently.

## How the sync works

The script reads `sync-config.psd1` and `pat.txt` from its own folder,
downloads the data repo's zipball, and robocopies each mapped project into
place. The config is `.psd1` rather than `.ps1` on purpose: it parses as data,
so it can never execute anything. The script then self-updates from
`$engineUrl`, overwriting itself only on a hash difference.

`/MIR` is `/E` plus `/PURGE` — it deletes anything in a destination that the
matching project folder does not hold. The script always excludes its own four
files, which is what stops a destination pointed at the sync folder from
deleting `pat.txt` on the first run and locking you out of every run after it.
Anything else that must survive goes in the config's `keep`.

### When a pull breaks

A scheduled run is hidden, so failures announce themselves: a message box, and
`pull-problems.log` beside the script. The log records problems only — a clean
pull never touches it, so its timestamp answers "when did this last go wrong",
and no file at all means it never has. Trimmed to the last 200 entries. Mostly
this exists to name the day your PAT expires.

Run it from the desktop shortcut instead and you get the console, which reports
each project as it syncs.

### Notes

Sync is one-way. Do not edit mirrored files locally; `/MIR` reverts them at the
next pull without warning. The single exception is a thread writing content it
has just pushed.

On-logon is a deliberate choice, not a limitation. Threads with desktop access
write to the drive themselves; threads without it are the only ones that need
the pull, and next logon is soon enough. Use `/sc daily` or anything else
`schtasks` accepts if that suits you better.

### Adding a project

1. Create `contexts/<project>/` in the data repo.
2. Add a `map` entry in `sync-config.psd1` on the PC.
3. Point the project's instructions at `contexts/<project>/`.
