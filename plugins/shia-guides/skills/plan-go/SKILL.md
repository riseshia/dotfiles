---
description: Execute plan
userInvocable: true
arguments: filename
---

# Plan Go

## Workflow

1. Read the specified `{filename}` and grasp the overall picture of the plan
2. If the plan defines TDD steps, follow that order. Otherwise, determine the implementation order from the plan's structure
3. Implement each step in sequence
   - Briefly declare what you will do before starting each step
   - If there are tests, write the test first (Red)
   - Write the minimal code to make the test pass (Green)
   - Refactor as needed (Refactor)
   - After completing each step, verify with `bun run typecheck && bun test` (or the project's verification command)
4. After all steps are complete, perform a final check according to the plan's verification section
5. After implementation is complete, delete the plan file

## Constraints

- Do not do anything not described in the plan. Do not make out-of-scope improvements or refactors.
- If an implementation contradicts the plan, stop and confirm with the user.
- Do not break existing tests. If tests break, identify the cause and fix it.
