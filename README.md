# claude_link

One-way context sync for Claude projects. A Claude thread pushes markdown
notes to a private GitHub repo; a scheduled PowerShell pull mirrors them
onto your PC, so the next thread — in the browser, on the desktop,
wherever — starts with the context the last one left behind.

    Claude thread  ->  private data repo  ->  your PC

The repo is authoritative. Files not in it get wiped locally.

## Three places, one job each

| Where | Holds | Visibility |
|---|---|---|
| **this repo** | `pull-context.ps1`, and the protocol threads follow | public |
| **your data repo** | `contexts/<project>/` — nothing else | private |
| **the sync folder on your PC** | `pat.txt`, `sync-config.psd1` | never leaves the machine |

The split is the point: the code is public and contains nothing about you,
the data is private, and the credential plus the machine-specific paths
stay on the machine that needs them. Nothing personal is ever committed
anywhere public, and no repo holds a token.

## If you are forking this

The script updates itself on every pull, from the URL in its own
`$engineUrl`. That URL points at **this** repo. So a copy taken as-is
keeps pulling my script onto your machine forever — quietly overwriting
any change you make to your fork, and running whatever I push here.

Before you run anything, edit `$engineUrl` at the top of
`pull-context.ps1` to point at your own fork, and fetch from your fork in
step 3 below. Then the loop closes on you rather than on me. Do the same
with the `dukepeet/claude_link` reference in the project-instructions stub
in step 6 — that one only decides which README your threads read, so it is
harmless either way, but consistency beats surprise later.

## Setup

**1. Create a private data repo.** Initialize it with a README so it has a
default branch. It will only ever contain `contexts/<project>/` folders.

**2. Create a fine-grained PAT** scoped to just that repo, with
Repository permissions → **Contents: read**. Read is enough — the PC only
pulls. Your Claude threads push through their own GitHub connection, not
through this token.

**3. Bootstrap the PC.** Single-line commands, one at a time, in
PowerShell. Replace `C:\claude-sync` with wherever you want the sync
folder, and `dukepeet/claude_link` with your fork.

    New-Item -ItemType Directory -Force C:\claude-sync | Out-Null; "PASTE_PAT" | Set-Content C:\claude-sync\pat.txt

    Invoke-WebRequest "https://raw.githubusercontent.com/dukepeet/claude_link/main/pull-context.ps1" -OutFile C:\claude-sync\pull-context.ps1

    Invoke-WebRequest "https://raw.githubusercontent.com/dukepeet/claude_link/main/sync-config.example.psd1" -OutFile C:\claude-sync\sync-config.psd1

    schtasks /create /tn "Claude context pull" /tr "powershell -NoProfile -ExecutionPolicy Bypass -w hidden -f C:\claude-sync\pull-context.ps1" /sc onlogon /f

    $d = [Environment]::GetFolderPath("Desktop"); $s = (New-Object -ComObject WScript.Shell).CreateShortcut("$d\Pull context.lnk"); $s.TargetPath = "powershell.exe"; $s.Arguments = "-NoProfile -ExecutionPolicy Bypass -f C:\claude-sync\pull-context.ps1 -wait"; $s.Save()

**4. Edit `sync-config.psd1`.** Set `repo` to your data repo and add one
`map` entry per project — the folder name under `contexts/`, and where it
should land locally.

**5. Run it** from the desktop shortcut. A healthy run prints each project
and `OK`.

Only the script fetch is ever needed again, and not even that: after the
first run the script replaces itself from its `$engineUrl` on every pull,
so a change pushed there is the whole deployment.

**6. Point each Claude project at its folder.** In the project's
instructions:

    Context project: myproject (contexts/myproject/ in you/your-context-data).
    Requires the GitHub connector. If its tools are missing, enable it for
    this conversation.
    Before any context file work, read README.md from dukepeet/claude_link
    and follow it.

That stub has to name the connector, because the README it points at is
unreadable until the connector works.

## Protocol for Claude threads

This section is what your threads read. It governs the data repo.

Your project's folder is `contexts/<project>/`, named in the project
instructions. Write only inside it. Never add, edit, or delete anything
outside it on your own initiative — another project's folder, or the repo
root — even to correct something that looks stale.

Report it to the user, name the thread that owns it, and offer to write a
handoff instead of doing the work. If the user tells you to do it here
anyway, do it — but make the offer first, every time. Approval is not the
test at this boundary; ownership is. Asking "may I?" invites yes, and a
thread that keeps asking absorbs another thread's work one approval at a
time.

**Fetch before every push.** `push_files` overwrites whatever is on
`main`. There are no branches and no PRs here, so nothing surfaces a
conflict and nothing stops you silently clobbering work another thread
pushed while your thread was thinking. Immediately before pushing a file
that already exists, call `get_file_contents` on it and merge your changes
into what comes back. Both project knowledge and anything you read earlier
in the same thread may already be stale.

**Push immediately.** Every time you write or substantially rewrite a
context file, push it in the same turn — do not wait for the user to say
"dump". "dump" stays valid as a manual catch-up for anything missed.

1. List `contexts/<project>/` and `contexts/<project>/handoffs/` before
   the thread's first push. Reuse existing filenames exactly; never invent
   a variant of a name already there. Mention any handoffs you find — you
   cannot tell which are addressed to you, so let the user say.
2. Re-fetch every existing file you are about to overwrite, in the same
   turn as the push. A copy you read earlier in the thread does not count
   — re-read it.
3. Push full final content. Holding only part of a file, say so and skip
   it.
4. Use `push_files` — one commit, no blob SHA needed for overwrites.
   Message: `context dump <date>`.
5. Never create branches or PRs. Never delete files, except an actioned
   handoff addressed to you.
6. Reply with paths written, flagging any that already existed.

Never put credentials, tokens, or machine-specific paths in the data repo.
Those live in the sync folder on the PC, which no repo can see.

### Handoffs

A note from one thread to another in the same project, living in
`contexts/<project>/handoffs/`. It is how work that belongs elsewhere
moves without the raising thread doing it.

- Filename is `<owner>--<subject>.md`. The owner is the recipient, since
  the folder narrows to a project and not to a thread; the sender goes in
  the body.
- Create, do not edit. A handoff you did not write is not yours to
  rewrite — raise a new one instead. Create-only means there is no way to
  clobber someone else's.
- Delete it once actioned. Git keeps the history.
- The owner name should read as a topic, so a thread that does not exist
  yet can still be the recipient.

### Writing straight to the PC

If the thread can reach a project's local folder, write the same final
content there too, immediately after pushing — it saves waiting for the
next pull.

This is **best effort**. Content identical to the repo makes the next
`/MIR` a no-op, and if a pull wipes it anyway nothing is lost, because the
repo already has it. So: only ever write content that has already been
pushed, and never treat the local write as a substitute for the push. If
the folder isn't reachable, skip it silently — the next pull covers it.

Filenames: kebab-case slugs, `.md`.

## How the sync works

`pull-context.ps1` reads `sync-config.psd1` and `pat.txt` from its own
folder, downloads the data repo's zipball, and robocopies each project
folder to its mapped local path. The config is `.psd1` rather than `.ps1`
on purpose: it is parsed as data, so it can never execute anything.

It then updates itself from `$engineUrl` — an unauthenticated fetch, since
that repo is public — comparing hashes and overwriting only on a
difference. See "If you are forking this" above.

`$keep` is the counterweight to `/MIR`, which is `/E` plus `/PURGE`: it
deletes anything in a destination that the matching project folder does
not hold. The script always protects its own four files. If you point a
project's destination at the sync folder itself — a reasonable thing to do
— that protection is what stops the first pull deleting `pat.txt` and
locking you out of every pull after it. Anything else that must survive in
a destination goes in the config's `keep`.

### Knowing when a pull breaks

A scheduled run is hidden, so the script raises its own alarm. Both
channels are silent when nothing is wrong.

`pull-problems.log`, beside the script, records **problems only** — a
failure, or a non-fatal oddity like a mapped project with no folder in the
repo. A clean pull does not touch the file, so its timestamp answers "when
did this last go wrong", and no file at all means it never has. Trimmed to
the last 200 entries.

A run that fails while unattended also pops a message box. Run it from the
desktop shortcut instead and you get the console, which reports each
project as it syncs.

Fine-grained PATs expire, so this is mostly there to name the day your
token runs out.

### Notes

Sync is one-way. Do not edit mirrored files locally; `/MIR` reverts them
at the next pull without warning. The single exception is a Claude thread
writing content it has just pushed — see above.

On-logon is a deliberate choice, not a limitation. Threads with desktop
access write to the drive themselves; threads without it are the only ones
that need the pull, and next logon is soon enough for those. Use
`/sc daily` or anything else `schtasks` accepts if that suits you better.

### Adding a project

1. Create `contexts/<project>/` in the data repo.
2. Add a `map` entry in `sync-config.psd1` on the PC.
3. Point the project's instructions at `contexts/<project>/`.
