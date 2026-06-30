# State: plan-approve (HUMAN GATE)

Role: the workflow's single human decision point — decide **direction** (is the plan right?). This is a gate state: the CLI will not let you leave it (via `revise` or `resume`) without a prior `approve`. **Stop and wait for the user here.**

Steps:

1. Read `.workflow/plan.md` and grasp the overall picture.
2. **Critical analysis** — inspect for: ambiguity, overlooked cases (edge cases, error handling, consistency with existing code), implicit assumptions, unjustified design choices, unclear scope.
3. Fix what you can confidently resolve by editing `.workflow/plan.md`. For anything that genuinely needs the user's decision, leave a single `AI-ASK: <question>` line at the relevant spot.
4. **Present, then end your turn and wait.** Do not fire any event in the same turn as the presentation. Present:
   - a 3-5 line summary of the plan
   - all `AI-ASK:` questions (if any)
   - the branch name you intend to use

When the user responds, run `bash <skill-dir>/workflow.sh approve` to record their sign-off, then fire the matching event:
- **Changes requested, or any `AI-ASK` still unanswered** -> fold the answers/changes into `.workflow/plan.md`, then `bash <skill-dir>/workflow.sh fire revise` (returns to `plan` to update). Do not `resume` while an `AI-ASK` is unresolved.
- **Approved as-is** -> `bash <skill-dir>/workflow.sh fire resume` (-> `implement`).

Without a prior `approve`, the CLI rejects both `revise` and `resume`. The approval is consumed on firing, so re-entering the gate requires re-approval. Only if the user pre-authorized skipping review ("just go") may you `approve` + `resume` immediately; say so in one line.
