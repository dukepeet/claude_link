# Protocol for Claude threads

This is what a Claude thread reads and follows. It governs the private data
repo that holds context files — one folder per project, mirrored to a PC by
`pull-context.ps1`. See [README.md](README.md) for how the sync works.

Your project's folder is `contexts/<project>/`, named in the project
instructions.

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

## Handoffs

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

## Writing straight to the PC

If the thread can reach a project's local folder, write the same final content
there too, immediately after pushing — it saves waiting for the next pull.

This is **best effort**. Content identical to the repo makes the next `/MIR` a
no-op, and if a pull wipes it anyway nothing is lost, because the repo already
has it. So: only ever write content that has already been pushed, never treat
the local write as a substitute for the push, and if the folder isn't
reachable, skip it silently.
