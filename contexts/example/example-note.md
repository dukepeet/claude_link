# Example context file

Everything under `contexts/example/` is mirrored to whatever local path
`example` maps to in `$map`. Replace this folder with one per project.

A context file is just markdown. It exists so a Claude thread that has
never seen your project can pick up where the last one left off:
decisions you made and why, constraints, paths, things that turned out
not to work. Write it for a stranger, because that is what the next
thread is.

Filenames are kebab-case slugs ending in `.md`.

A thread with access to this repo writes here itself — see the protocol
in the README. You mostly will not touch these files by hand.
