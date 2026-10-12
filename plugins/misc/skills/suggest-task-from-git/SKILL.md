---
name: suggest-task-from-git
description: Read the recent Git history and suggest the single next task to work on, skipping tasks the user rejected before. Suggestion only; does not do the work. Human-invoked only.
user-invocable: true
disable-model-invocation: true
arguments: hint
---

# Suggest Task from Git

Look at the Git history and suggest one next task. Do not modify the repository.

## Context

- Status: !`git status --short`
- Recent commits: !`git log --oneline -20`
- Rejection log path: !`echo "$HOME/.local/state/suggest-task-from-git/$(git rev-parse --show-toplevel | tr / -)/rejected.md"`
- Previously rejected tasks: !`cat "$HOME/.local/state/suggest-task-from-git/$(git rev-parse --show-toplevel | tr / -)/rejected.md" 2>/dev/null || echo "(none)"`

## Steps

1. Look into the recent commits that look relevant (`git show`, `git diff`) — follow-up work usually shows up as unfinished changes, TODOs introduced by a commit, missing tests or docs, or inconsistencies left between related files.
2. Drop any candidate that matches a previously rejected task, including the same task reworded.
3. If the user passed a hint, prefer tasks along that direction.
4. Pick the single most worthwhile task and suggest it.

## Output

- **Task**: one line
- **Why**: why this is next, citing the commits or files it comes from
- **Where to start**: concrete files or first steps

Add up to two alternatives in one line each only if they are close calls.

## On rejection

When the user rejects a suggestion, append it to the rejection log (create the directory if needed) as one line: `- <date> <task>: <reason if given>`. Then suggest the next candidate if the user wants one.
