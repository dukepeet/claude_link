# claude_link

One-way context sync for Claude projects. A thread pushes markdown notes to a
private GitHub repo; a scheduled PowerShell pull mirrors them onto your PC, so
the next thread — browser, desktop, wherever — starts with the context the last
one left.

    Claude thread  ->  private data repo  ->  your PC

The repo is authoritative: files not in it get wiped locally.

**If you are a Claude thread sent here, read [PROTOCOL.md](PROTOCOL.md).** The
rest of this file is setup, for a person.

| Where | Holds | Visibility |
|---|---|---|
| this repo | `pull-context.ps1`, and the protocol threads follow | public |
| your data repo | `contexts/<project>/`, nothing else | private |
| sync folder on your PC | the script, `pat.txt`, `sync-config.psd1`, the log | never leaves the machine |

The split is the point: public code that says nothing about you, private data,
and the token plus machine-specific paths staying on the machine that needs
them. No repo holds a token.

The two directions authenticate differently. Threads push through a GitHub
connector in Claude, authorized as your GitHub account. The PC pulls with a
fine-grained token that only needs read. Nothing needs a read-write token.

## Self-update

By default the script re-fetches itself from this repo on every pull and
overwrites itself when the copy here differs. That means a change pushed here
is the whole deployment — and also that code you do not control changes on your
machine without you doing anything. Decide which you want:

- **Leave it alone** to track this repo.
- **`engineUrl = ''`** in `sync-config.psd1` pins the script you have. Nothing
  self-updates; you re-fetch by hand when you choose.
- **`engineUrl = '<your raw URL>'`** tracks your own copy instead, if you have
  changed the engine and still want it deployed automatically.

The setting lives in the config rather than in the script because the script
overwrites itself — a value edited into the script would be undone on the next
pull.

## Setup

**1. Create a private data repo**, initialized with a README so it has a
default branch. It holds only `contexts/<project>/` folders.

**2. Create a fine-grained PAT** scoped to that repo, Repository permissions →
**Contents: read**. Read is enough: the PC only pulls.

**3. Bootstrap the PC.** One line at a time in PowerShell. Replace
`C:\claude-sync` with wherever you want the sync folder.

    New-Item -ItemType Directory -Force C:\claude-sync | Out-Null; "PASTE_PAT" | Set-Content C:\claude-sync\pat.txt

    Invoke-WebRequest "https://raw.githubusercontent.com/dukepeet/claude_link/main/pull-context.ps1" -OutFile C:\claude-sync\pull-context.ps1

    Invoke-WebRequest "https://raw.githubusercontent.com/dukepeet/claude_link/main/sync-config.example.psd1" -OutFile C:\claude-sync\sync-config.psd1

    schtasks /create /tn "Claude context pull" /tr "powershell -NoProfile -ExecutionPolicy Bypass -w hidden -f C:\claude-sync\pull-context.ps1" /sc onlogon /f

    $d = [Environment]::GetFolderPath("Desktop"); $s = (New-Object -ComObject WScript.Shell).CreateShortcut("$d\Pull context.lnk"); $s.TargetPath = "powershell.exe"; $s.Arguments = "-NoProfile -ExecutionPolicy Bypass -f C:\claude-sync\pull-context.ps1 -wait"; $s.Save()

**4. Edit `sync-config.psd1`.** Set `repo` to your data repo, and add a `map`
entry per project: the folder name under `contexts/`, and where it lands
locally. Set `engineUrl` here too if you want anything other than the default.

**5. Run it** from the desktop shortcut. A healthy run prints each project and
`OK`.

**6. Connect Claude to GitHub.** Threads reach the data repo through a custom
connector pointed at GitHub's remote MCP server. It authenticates with a GitHub
OAuth App you create — GitHub's server does not support dynamic client
registration, so leaving the OAuth fields blank fails.

On GitHub, Settings → Developer settings → **OAuth Apps** → New OAuth App.
Not GitHub Apps; they sit next to each other and use an install flow this does
not complete. Homepage URL can be anything. Authorization callback URL must be
exactly:

    https://claude.ai/api/mcp/auth_callback

Register it, copy the Client ID, generate a client secret and copy that too —
it is shown once.

In Claude, Settings → Connectors → Add custom connector. URL:

    https://api.githubcopilot.com/mcp/x/repos

The `/x/repos` path selects the repository toolset. Put the Client ID and
secret in Advanced settings, save, then Connect and authorize. Connectors can
only be added from a browser, not the mobile app.

Test it before going further: in a chat, enable the connector from the `+`
menu and ask it to write a file to your data repo. A token that cannot see the
repo returns 404 rather than a permission error, so a wrong scope looks like a
wrong repo name.

**Scope caveat.** OAuth App authorization is account-wide — the connector can
reach every repo your GitHub account can, not just the data repo. There is no
per-repo OAuth App. To contain it, authorize the connector as a separate GitHub
account that is a collaborator on the data repo and nothing else; account-wide
scope stops mattering when the account reaches one repo. GitHub permits one
free machine account per person. Otherwise, blocking individual tools under
Customize → Connectors limits what the connector can do, though not where.

**7. Point each Claude project at its folder**, in the project's instructions:

    Context project: myproject (contexts/myproject/ in you/your-context-data).
    Requires the GitHub connector. If its tools are missing, enable it for
    this conversation.
    If the tools are unavailable, say so before anything else and stop —
    do not answer from memory. This conversation cannot see the context
    files, and nothing in this prompt substitutes for them.
    Before any context file work, read PROTOCOL.md from dukepeet/claude_link
    and follow it.

The stub has to name the connector, because the file it points at is unreadable
until the connector works. The stop instruction matters because the failure is
otherwise silent: a thread with no tools answers plausibly from general
knowledge and nothing looks wrong.

Do not keep copies of the context files in the project's knowledge. A thread
reads the repo, so a second copy serves only a surface where the connector is
unavailable — and it has to be maintained by hand, drifts silently when someone
forgets, and sits in the system prompt of every conversation in the project,
where a stale copy misinforms rather than merely going unused. If you do work
somewhere connector-less often enough to want a copy, add the data repo through
the project knowledge section and scope it to that project's folder, so the
copy is generated and refreshed with one button rather than typed.

## How the sync works

The script reads `sync-config.psd1` and `pat.txt` from its own folder,
downloads the data repo's zipball, and robocopies each mapped project into
place. The config is `.psd1` rather than `.ps1` on purpose: it parses as data,
so it can never execute anything. The script then self-updates, unless
`engineUrl` is empty.

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

### When a thread cannot reach the repo

The stub tells it to stop, but that is a self-report and will sometimes fail.
The reliable tell is on your side: a thread that answers a question about
project context without a visible tool call has not read anything, whatever it
says about itself.

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
