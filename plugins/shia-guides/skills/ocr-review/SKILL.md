---
name: ocr-review
description: High-precision code review inspired by Alibaba Open Code Review. Script-driven pre-processing, per-file isolated review, three-layer false-positive reduction.
user-invocable: true
version: 0.4.0
license: CC0-1.0
---

# OCR Review

High-precision code review inspired by [Alibaba Open Code Review](https://github.com/alibaba/open-code-review).

Core insight: **deterministic engineering for precision-critical steps beats prompt engineering alone.** File selection, filtering, checklist routing, and context composition are handled by scripts. LLM judgment is reserved for code understanding and issue identification.

**Limitations:** This is not a static analyzer. It does not guarantee full coverage. It intentionally trades recall for precision. For security-critical review, pair with tests and SAST tools.

---

## Step 1: Run `preprocess.sh`

```
bash <skill-dir>/preprocess.sh [diff-target]
```

- No argument: diffs against merge-base of main/master
- `staged` / `HEAD` / branch name / commit SHA / range (`a..b`)
- `--include-tests`: include test files (excluded by default)

Read the output. Key fields:
- `diff_base`: the git ref to pass to `file-context.sh`
- `[REVIEW]` section: one line per reviewable file — `path  status  changed_lines  plan_needed  checklists`

If `reviewable_count: 0`, report "No reviewable files changed." and stop.

---

## Step 2: Per-file review

For each file in `[REVIEW]`, run:

```
bash <skill-dir>/file-context.sh <diff_base> <filepath> <checklists...>
```

This outputs the complete review input: other changed files, unified diff, and composed checklists — all structured as XML-like blocks. Read the output and review it.

### Plan phase (if plan_needed = yes)

For files with >50 changed lines, produce a brief plan before reviewing:
- One-sentence change summary
- Risk areas ordered by severity (high > medium > low)
- Which areas need additional context to confirm

Use this as advisory guidance — not binding.

### Review

Review the diff against the composed checklist from `<review_checklist>`. Gather additional context (Read file, Bash grep/find) **only** to confirm or reject a suspected issue.

### Scope rules

**DO:**
- Focus on newly added and modified code.
- Verify suspected issues via tools before reporting.
- Be objective — judge based on facts and logic, not assumptions.
- Report nothing if no clear issues exist.

**DO NOT:**
- Comment on deleted code (reference context only).
- Comment on correct or unchanged code.
- Comment on non-functional elements: comments, annotations, metadata, formatting.
- Report issues discovered in other files while gathering context.
- Report speculative issues. If not confident, suppress.

---

## Step 3: Self-filter ("falsify, not verify")

After all findings, evaluate each as a skeptic trying to disprove it. Remove any that fails:

1. **In changed code?** If the issue is in unchanged diff context, remove.
2. **Supported by diff or inspected context?** If it relies on assumptions about unread code, remove.
3. **Possible false positive from missing context?** If the code might be correct given unseen context (caller handles error, framework guarantee), remove.
4. **Fix practical and local?** If the fix requires changes outside this diff, demote or remove.
5. **Style-only?** Unless it causes correctness, security, or operational risk, remove.

Prefer false negatives over false positives. When in doubt, suppress.

---

## Output format

Per finding:

```
### [severity] path/to/file.ext:L15-L20 -- Short title

**Issue:** What is wrong.
**Why it matters:** Concrete consequence.
**Suggested fix:**
```diff
- existing problematic code
+ suggested replacement
```
```

Severity: `critical` | `high` | `medium` — do not report `low`.

Summary:

```
## Review summary

Files reviewed: N
Findings: N (X critical, Y high, Z medium)

[findings grouped by file]
```

No findings: `No issues found. Looks good to me.`
