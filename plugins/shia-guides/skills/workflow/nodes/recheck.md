# State: recheck

Role: **decide to ship.** A confidence gate on the integrated final state — not a place to find new design issues (those belong to `validate`). A worker (`workers/recheck.txt`, run via `claude -p`) re-verifies in a fresh process and returns a result. Do NOT verify inline.

Steps:

1. Run the worker:
   ```
   bash <skill-dir>/workflow.sh work
   ```
2. Route on the returned `RESULT`:
   - `READY` -> `bash <skill-dir>/workflow.sh fire pr`.
   - `NOT-READY` -> overwrite `.workflow/feedback.md` with the reason (markdown bullets), then `bash <skill-dir>/workflow.sh fire continue "<one-line reason>"`. Last-chance loop (bounded by the `continue` guard): a problem that escaped `validate` reappeared. If `continue` is exhausted, do not ship — `bash <skill-dir>/workflow.sh fire exit`.
   - `NOT-READY` resting **only** on a premise the human already resolved at the gate (a `task.md` constraint the plan withdrew) -> `bash <skill-dir>/workflow.sh fire pr "<one-line reason>"` instead of `continue`. Do not silently ignore it: the reason must name the superseded premise, and any part of the verdict that is not about that premise still routes to `continue`.

When the loop-back's feedback redefines the plan's **contract** (approach/scope/interface) rather than just fixing a defect, update `.workflow/plan.md` to match as you write `.workflow/feedback.md` — otherwise the re-entered `validate` compares the change against a stale plan and flags it as divergence.

The only ship path is a Draft PR — the human reviews the actual change there.
