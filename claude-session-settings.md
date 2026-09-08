# Session settings

Read when the session's type is clear — usually the first turn — per
PROTOCOL.md, Session settings. Name the matching model and effort once,
then carry on; on a mismatch, stop. Session types are shapes, not topics:
one file serves every project. Effort labels are placeholders for whatever
the selector shows. When models change, this table is the only place to
update.

| Session type | Looks like | Model | Effort |
|---|---|---|---|
| Lookup | What does file X say; what's ordered; what's the SHA. Reads only, and of the repo: what a tool does is a Question, not a Lookup. | Haiku 4.5 | low |
| Question | One answer, no file written, a turn or two. | Sonnet 5 | high — set and forget; cost scales with turn count, and one turn is a rounding error |
| Note update | Record a decision already made; fix a stale line; apply an existing rule to a case; one file. | Sonnet 5 | medium |
| Facilitation | A live sitting: the user drives the tool and reports what it shows; the thread logs and derives. Many short turns; findings triaged to files at the end. | Sonnet 5 | medium, low if quality holds; high for the closing review turns, then back down |
| Design | Changes a role, a rule, a Rejected or Not decided line — rewriting what a rule says, not applying it; touches more than one file. A wrong call costs a rewrite git can undo. | Opus 5 | high |
| Diagnosis | A call whose wrong answer is paid outside the repo — a purchase, a physical change, a fix built on a wrong root cause, a plan structure months of work will follow. Usually an evidence loop that ends in a verdict. | Fable 5.1; Opus 5 for a long loop, or when quota bites | high; see Inside Diagnosis |

Fable earns its burn only where a wrong call is paid outside the repo, and
only on the turns that make the call.

## Escalation

Switch to the Design line — Diagnosis when the cost lands outside the
repo — before the work, when any other line turns into:

- a "should I…" whose answer would change a Rejected or Not decided item
- a change that touches more than one file
- a call where a wrong answer means redoing work outside the repo — a
  sitting or a question that has turned diagnostic, or a review turn that
  reopens plan structure, which is drafting in disguise

Raise it in the turn it happens, as switch if / stay if, and stop.

## Inside Diagnosis

- Open on Fable, high.
- An evidence loop — run test, report numbers, next step, repeat — is a
  long agentic run: xhigh. When it runs long enough for Fable's burn to
  compound, or quota bites, the loop drops to Opus 5.
- The verdict turn — root-cause call plus fix order, or the single decision
  everything after propagates from — is back on Fable at max, for that turn
  only: nothing follows it to de-escalate for.

## Fixed

- No tier or effort adds knowledge. Recall of what a tool or file does goes
  to the tool or file at every level; effort pays only where the answer is
  derived from constraints.
- Escalation does not fix a not-rereading slip. Tier and effort govern
  reasoning depth, not whether content already fetched into the thread gets
  checked before answering; that wants a re-read, not a switch.
- Thinking on wherever the selector offers it: the trace is how a
  procedural claim's derivation gets checked before it is trusted.

## Adding a type

A project that seems to need its own settings is a shape this table is
missing. Add the row here; context folders hold project data only.
