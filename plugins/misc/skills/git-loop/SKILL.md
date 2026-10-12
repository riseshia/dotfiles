---
name: git-loop
description: Run `claude -p` in an endless shell loop where each iteration reads the Git history and per-repo carried-over state, picks the next task itself, does it, and commits. Human-invoked only.
user-invocable: true
disable-model-invocation: true
arguments: hint
---

# Git Loop

An endless loop. Each iteration is a fresh `claude -p` that reads the Git history, decides what to do next, does it, and commits. Nothing else drives it.

State is kept outside the repo, per repository, under `~/.local/state/git-loop/<repo path with / replaced by %>/`:

- `state.md` — notes carried to the next iteration (what was done, what is next, open questions). Each iteration rewrites it.
- `hint.md` — optional standing direction from the human. Iterations read it but never edit it.
- `log/<timestamp>.log` — output of each iteration.

Because state is keyed by the repository path, stopping and restarting the loop resumes from the previous `state.md`.

## Steps

1. Confirm the current directory is inside a Git repository (`git rev-parse --show-toplevel`). Stop if not.
2. If the user passed a hint, write it to `hint.md` (overwrite).
3. Start `${CLAUDE_SKILL_DIR}/loop` with the Bash tool using `run_in_background: true`, from the repository root.
4. Tell the user the state directory and how to stop: `touch <state dir>/stop` (the loop exits after the current iteration), or kill the background task.

Do not do any iteration work yourself; the loop runs separately.

## Options (environment variables)

- `GIT_LOOP_INTERVAL` — seconds to sleep between iterations (default 10)
- `GIT_LOOP_PERMISSION_MODE` — passed to `--permission-mode` (default `auto`)
- `GIT_LOOP_MODEL` — passed to `--model` when set
