# Protocol for Claude threads

This is what a Claude thread reads and follows. It governs the private data
repo that holds context files — one folder per project, mirrored to a PC by
`pull-context.ps1`. See [README.md](README.md) for how the sync works.

This file changes. A conversation can outlive several versions of it, and
nothing announces an edit, so a copy you read earlier in the thread may already
be wrong. Re-read it in any turn where you touch context files — step 1 below
puts that next to something you already do.

**This file wins.** It overrides anything you inferred earlier in the
conversation, settled into as a habit over several turns, or hold as a stored
preference. A pattern you established before the current version of this file
is not evidence about what to do now. Where this file is silent or ambiguous,
say so and ask — do not fill the gap from assumption and carry on.

Your project's folder is `contexts/<project>/`, named in the project
instructions.

**The repo is the only store.** Context files live there, and on the user's PC
via the pull. Never write them into the claude.ai project's knowledge: nothing
syncs the two, so a copy there goes stale the moment the repo moves on, and it
sits in the system prompt of every conversation in the project where it
misinforms rather than merely going unused. Anything you find there is a
leftover. A project whose knowledge holds no context files is correct, not
damaged.

**Stay in your folder.** Never add, edit, or delete anything outside it on your
own initiative — another project's folder, or the repo root — even to correct
something that looks stale. Report it, name the project that owns it, and offer
to write a handoff instead of doing the work. If the user tells you to do it
here anyway, do it — but make the offer first, every time. Approval is not the
test at this boundary; ownership is. "May I?" invites yes, and a thread that
keeps asking absorbs another project's work one approval at a time.

**Absence is a signal, not an error.** If a file you expected is gone, say so —
do not recreate it. It was far more likely deleted on purpose than lost, and
restoring it silently undoes that decision. This holds inside your own folder
too, where you are otherwise free to write: the freedom is to add and update
what the work needs, not to restore what someone removed.

**Deleting on instruction.** A file the user tells you to delete, you delete.
Say what makes it deletable first — a name, not a gesture: which file
supersedes it, where its content went, or that it was decided against. Git
keeps the history, so the cost of a wrong delete is a revert, not a loss;
the cost of a silent one is that neither of you notices the wrong file went.

The rule this qualifies is about **initiative**, not permission: absence
stays a signal, and a file that merely looks stale still gets reported
rather than removed. What changes is only that "the user said to" is now an
answer to *why is this going*, where before it was not.

**Fetch before every push.** `push_files` overwrites whatever is on `main`. No
branches, no PRs, so nothing surfaces a conflict and nothing stops you silently
clobbering what another thread pushed while your thread was thinking. Project
knowledge and anything you read earlier in the thread may already be stale.

**Offer the push immediately; wait to make it.** Every time you write or
substantially rewrite a context file, say so in the same turn and offer to push
it — do not sit on it until the user thinks to ask. But the push itself waits
for their word. Name the paths and say what is going into each, so they know
what would land before it does: a push reaches their machine at the next pull,
and a file they did not expect is worse than one that arrives a turn later.
"dump" stays valid as a manual catch-up for anything missed.

1. Re-read this file, and list `contexts/<project>/` and its `handoffs/`, in
   every turn where you touch context files — not just the first. Reuse
   existing filenames exactly; never invent a variant of a name already there.
   Mention any handoffs you find — you cannot tell which are addressed to you,
   so let the user say. If the folder has a `README.md`, read it before adding,
   moving, or renaming anything: that is where the project's own layout rules
   live.
2. Re-fetch every existing file you are about to overwrite, in the same turn as
   the push. A copy you read earlier in the thread does not count.
3. Push full final content. Holding only part of a file, say so and skip it.
4. Once the user has agreed, use `push_files` — one commit, no blob SHA needed
   for overwrites. Message: `context dump <date>`, then one line per fact file
   the commit changes, naming the journal entry that holds the finding —
   `rig/live-behaviour.md ← learning/rounds/round-01/!journal.md 1x01`. Fact
   files carry no history of their own; the commit message is where a fact's
   provenance lives, and the journal entry is where the finding is.
5. Never create branches or PRs. Never delete a file on your own initiative,
   with two exceptions: an actioned handoff addressed to you, and a file the
   user has told you to delete. Say what makes it deletable before you do it
   — superseded by X, moved to Y, decided against — and stop if you cannot,
   because a delete you cannot explain is one you have misunderstood.
6. Reply with paths written, flagging any that already existed.

Never put credentials, tokens, or machine-specific paths in the data repo.
Those live in the sync folder on the PC, which no repo can see.

## Session settings

`claude-session-settings.md`, next to this file, maps session types to a
model and effort level and names the escalation triggers. It is generic —
session types are shapes, not topics — and no project carries its own.
Read it as soon as the session's type is clear, usually the first turn, and
surface the matching line inline: name the recommended model and effort
once. You cannot see the effort setting, so name the level and let the user
check the selector rather than claiming a mismatch.

**On a model mismatch, stop.** If the model you are running as is not the
recommended one, say so and recommend, as *switch if… / stay if…*, with each
condition filled in from what this session is about to do, so the choice can
be made from that line alone. Read the model you are running as in the turn
the check fires, not from an earlier turn — the user often switches ahead of
the flag, and a flag raised from a stale reading wastes a turn. Then end the
turn without starting the work: no analysis, no draft, nothing the user would
discard after switching. A model change applies from the next response, so an
answer produced on the wrong model is exactly the cost the check exists to
prevent. Carry on once they have switched or said to stay.

**Escalation.** The file names session shapes that warrant a switch
mid-thread. Raise the matching suggestion in the turn the trigger occurs,
in the same shape and before the work it concerns — not after it, and not
in a wrap-up: model and effort changes apply from the next response, so a
suggestion raised late buys nothing.

If the file is missing, say so, and judge the model from the first turn's
shape as a stopgap.

## Wrapping up

When the user says "wrap up", they are ending the conversation. Everything you
hold that is not in a file is about to be lost, and the next thread on this
topic starts from the files alone.

Write what a successor would need that the files do not already say:

- **Where the work actually stands.** A plan describes what is intended; it
  rarely records which part is done, in progress, or abandoned.
- **What was rejected, and why.** The most costly thing to lose — without it a
  later thread re-proposes what was already ruled out, and nothing flags that
  it is retreading.
- **What was decided here that never reached a file.** Conclusions from the
  conversation itself, which exist nowhere else.

Then:

- Name what you cannot fill in. "The plan lists stage 3 but I do not know
  whether it was completed" is worth more than a confident guess, because the
  user can answer it and a successor cannot.
- Update existing files rather than adding one. A new handover note is
  indistinguishable from live content to the thread that reads it next.
- Offer the push as normal. This is content the user should see before it
  lands, more than most.

Say plainly if there is nothing to add. A session that changed nothing worth
recording is a normal outcome, not a failure to find something.

## What belongs here

Notes, by default: markdown, kebab-case slugs, `.md`.

Anything else the project needs is allowed — a config, a data file, a script —
but everything under your folder lands on the user's drive at the next pull,
so:

- Ask before adding a file type the project does not already hold. The user
  may not want it arriving on disk.
- Executables and scripts only when the user asks for one. A `.ps1` that a
  thread decided to write shows up on their machine looking like it belongs
  there.
- No binaries. They bloat the pulled archive and make the history unreadable.
- No generated output that a script could rebuild locally. The repo is for
  things worth carrying between threads.

`/MIR` reverts local edits at the next pull, which is easy to forget for a
file that invites editing in place, like a script. Say so when you add one.

## Handoffs

A note from one thread to a later one in the same project, living in
`contexts/<project>/handoffs/`. It is how work that belongs to another topic
moves without the thread that noticed it doing the work.

- Filename is `<owner>--<subject>.md`. The owner is the topic the work belongs
  to — the folder already names the project — and the sender goes in the body.
- Create, do not edit. A handoff you did not write is not yours to rewrite —
  raise a new one instead. Create-only means there is no way to clobber
  someone else's.
- Delete it once actioned. Git keeps the history.
- Threads are short and own nothing; topics do. The owner name should read as
  a topic, so whichever later thread works on it is the recipient.

When the owning topic lives in a **different** project, there is no folder you
may write to — theirs is outside yours, and the repo root is too. Write the
note and give it to the user to carry. That is the intended route, not a
workaround: you frequently cannot name the destination project anyway, only
the thing that owns the decision, and the user can.

## Writing straight to the PC

If the thread can reach a project's local folder, write the same final content
there too, immediately after pushing — it saves waiting for the next pull.

This is **best effort**, and best effort means the attempt is the whole
obligation. Content identical to the repo makes the next `/MIR` a no-op, and if
a pull wipes it anyway nothing is lost, because the repo already has it. So:
only ever write content that has already been pushed, and never treat the local
write as a substitute for the push.

If the folder is unreachable — no desktop access, the app dropped, the path is
missing — skip it and say nothing. Do not report it, do not offer to write it
later, do not carry it as something to finish. The pull covers it on its own,
so there is no outstanding item and nothing for either of you to remember. A
local write that did not happen is not a loose end; it is an optimisation that
was not available.
