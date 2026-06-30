# State: plan

Role: the **requirements-and-design conversation**. A worker (`workers/plan.txt`, run via `claude -p`) investigates the repo and drafts the plan; the **orchestrator owns the human dialogue**. Do NOT investigate or draft inline.

Steps:

1. Run the worker:
   ```
   bash <skill-dir>/workflow.sh work
   ```
   It writes `.workflow/plan.md` and returns a SUMMARY + OPEN QUESTIONS.
2. **Hold the dialogue** (orchestrator): if there are OPEN QUESTIONS, ask the user — focused and batched, nothing the code already answers — then end your turn and wait. This is where human input belongs.
3. With the answers, append a short `## Decisions` note to `.workflow/plan.md` (so the worker sees them) and re-run `bash <skill-dir>/workflow.sh work` to refine. Iterate until OPEN QUESTIONS is "none".
4. Record the plan file: `bash <skill-dir>/workflow.sh set plan_file .workflow/plan.md`

Fire: `bash <skill-dir>/workflow.sh fire submit` -> `plan-approve`.
