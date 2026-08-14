# claude_link (template)

One-way context sync for Claude projects. A Claude thread pushes
markdown notes to a GitHub repo; a scheduled PowerShell script mirrors
them onto your PC, so the next thread — in the browser, in a desktop
session, wherever — starts with the context the last one left behind.

The flow is deliberately one-way:

    Claude thread  ->  GitHub  ->  your PC

The repo is authoritative. Files not in it get wiped locally.

## Is this for you

Use it if you keep long-running projects in Claude and want their
accumulated context to survive between conversations, on disk, under
version control, without copy-pasting anything.

You need: a GitHub account, Windows with PowerShell, and a Claude setup
that can reach GitHub (a connector, an MCP server, whatever gives your
threads `get_file_contents` and `push_files`).

## Setup

**1. Make your own copy.** Use this template, or fork it. Make your copy
**private** — it will hold your notes.

**2. Create a fine-grained PAT** with `contents: read` on that repo
only. Read is enough: the PC only ever pulls. Your Claude threads push
through their own GitHub connection, not through this token.

**3. Edit `pull-context.ps1`.** Set `$repo` to your copy, and `$map` to
one entry per project — the folder name under `contexts/`, and where it
should land locally.

**4. Run the bootstrap.** Single-line commands, one at a time, in
PowerShell. Replace `C:\claude-sync` with wherever you want the script
to live.

    New-Item -ItemType Directory -Force C:\claude-sync | Out-Null; "PASTE_PAT" | Set-Content C:\claude-sync\pat.txt

    Invoke-WebRequest "https://api.github.com/repos/YOU/YOUR-REPO/contents/pull-context.ps1" -Headers @{Authorization="Bearer $((Get-Content C:\claude-sync\pat.txt -Raw).Trim())"; Accept="application/vnd.github.raw"} -OutFile C:\claude-sync\pull-context.ps1

    schtasks /create /tn "Claude context pull" /tr "powershell -NoProfile -ExecutionPolicy Bypass -w hidden -f C:\claude-sync\pull-context.ps1" /sc onlogon /f

    $d = [Environment]::GetFolderPath("Desktop"); $s = (New-Object -ComObject WScript.Shell).CreateShortcut("$d\Pull context.lnk"); $s.TargetPath = "powershell.exe"; $s.Arguments = "-NoProfile -ExecutionPolicy Bypass -f C:\claude-sync\pull-context.ps1 -wait"; $s.Save()

    & C:\claude-sync\pull-context.ps1 -wait

Command two is only for first setup or recovery — after that the script
replaces itself from the repo on every pull, so pushing a change is the
whole deployment.

**5. Point each Claude project at its folder.** Put a stub like this in
the project's instructions:

    Context project: myproject (contexts/myproject/ in YOU/YOUR-REPO).
    Requires the GitHub connector. If its tools are missing, enable it
    for this conversation.
    Before any context file work, read README.md from that repo and follow it.

That stub has to name the connector, because the README it points at is
unreadable until the connector works.

## Protocol for Claude threads

This section is the point of the repo. It is what your threads read.

Your project's folder is `contexts/<project>/`, named in the project
instructions. Write only inside it. Never add, edit, or delete anything
outside it on your own initiative — another project's folder, or the
repo root (this README included) — even to correct something that looks
stale. Report it to the user and let them decide. Edit outside your own
folder only when the user asks for it, and only what they asked for.

**Fetch before every push.** `push_files` overwrites whatever is on
`main`. There are no branches and no PRs here, so nothing surfaces a
conflict and nothing stops you silently clobbering work another thread
pushed while your thread was thinking. Immediately before pushing a file
that already exists, call `get_file_contents` on it and merge your
changes into what comes back. Both project knowledge and anything you
read earlier in the same thread may already be stale.

**Push immediately.** Every time you write or substantially rewrite a
context file, push it in the same turn — do not wait for the user to say
"dump". "dump" stays valid as a manual catch-up for anything missed.

1. List `contexts/<project>/` before the thread's first push. Reuse
   existing filenames exactly; never invent a variant of a name already
   there.
2. Re-fetch every existing file you are about to overwrite, in the same
   turn as the push. A copy you read earlier in the thread does not
   count — re-read it.
3. Push full final content. Holding only part of a file, say so and
   skip it.
4. Use `push_files` — one commit, no blob SHA needed for overwrites.
   Message: `context dump <date>`.
5. Never create branches or PRs. Never delete files.
6. Reply with paths written, flagging any that already existed.

### Writing straight to the PC

If the thread can reach a project's local folder (its destination in
`$map`), write the same final content there too, immediately after
pushing — it saves waiting for the next pull.

This is **best effort**. Content identical to the repo makes the next
`/MIR` a no-op, and if a pull wipes it anyway nothing is lost, because
the repo already has it. So: only ever write content that has already
been pushed, and never treat the local write as a substitute for the
push. If the folder isn't reachable, skip it silently — the next pull
covers it.

Filenames: kebab-case slugs, `.md`.

## Layout

Anything more than one project needs lives outside `contexts/`, at the
root. Project folders hold only that project's own material.

- `contexts/<project>/` — mirrored to the PC, one folder per project
- `pull-context.ps1` — the sync script, shared by every project. Not
  mirrored: it deploys itself instead.
- `README.md` — this file, not mirrored

## How the sync works

`pull-context.ps1` downloads the repo zipball and robocopies each
project folder to its mapped local path. It reads the PAT from
`pat.txt` **next to itself** — the token is never stored in the repo.
The script uses `$PSScriptRoot`, so it can live anywhere as long as
`pat.txt` sits beside it.

It updates itself without being mirrored: the zipball it just unpacked
contains the root copy, so each run compares that against the running
file and overwrites it when they differ.

`$keep` is the counterweight. `/MIR` is `/E` plus `/PURGE`, so it
deletes anything in a destination that the matching project folder does
not hold. If you point a project's destination at the folder the script
runs from — which is a reasonable thing to do — then without `/XF $keep`
the first pull deletes `pat.txt`, and with the token gone no later pull
can authenticate. `$keep` is harmless when your destinations are
separate, and load-bearing when they are not. Anything else that must
survive in a destination has to be added to it.

### Knowing when a pull breaks

A scheduled run is hidden, so the script raises its own alarm. Both
channels are silent when nothing is wrong.

`pull-problems.log`, beside the script, records **problems only** — a
failure, or a non-fatal oddity like a mapped project with no folder in
the repo. A clean pull does not touch the file, so its timestamp answers
"when did this last go wrong", and no file at all means it never has.
Trimmed to the last 200 entries.

A run that fails while unattended also pops a message box. Run it from
the desktop shortcut instead and you get the console, which does report
each project as it syncs.

Fine-grained PATs expire, so this is mostly there to name the day your
token runs out.

### Notes

Sync is one-way. Do not edit mirrored files locally; `/MIR` reverts them
at the next pull without warning. The single exception is a Claude
thread writing content it has just pushed — see above.

On-logon is a deliberate choice of schedule, not a limitation. Threads
with desktop access write to the drive themselves; threads without it
are the only ones that need the pull, and next logon is soon enough for
those. Use `/sc daily` or anything else `schtasks` accepts if that suits
you better.

### Adding a project

1. Create `contexts/<project>/`.
2. Add a line to `$map` in `pull-context.ps1` and push it.
3. If the destination folder holds anything not mirrored from the repo,
   add those filenames to `$keep` too.
4. Point the project's instructions at `contexts/<project>/`.
