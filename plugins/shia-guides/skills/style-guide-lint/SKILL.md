---
name: style-guide-lint
description: Quality-check the code-style guide for contradictions, duplications, and ambiguous rules. Run after editing the code-style skill files.
user-invocable: true
version: 0.1.0
license: CC0-1.0
arguments: optional path to the guide directory (defaults to the code-style skill in this repo or plugin)
---

# Style Guide Lint

Detect contradictions and duplications across the code-style guide files before they drift apart. A duplicated rule is a latent contradiction: once one copy is edited and the other is not, the guide disagrees with itself.

**Output is a report.** Never apply fixes as part of this skill; propose them.

## Target files

Resolve the guide directory in this order:

1. The argument, if given.
2. `plugins/shia-guides/skills/code-style/` under the current repository, if it exists (linting the working copy).
3. The installed plugin's `code-style` skill directory (sibling of this skill's base directory).

Lint `SKILL.md` and every file under `reference/`.

## Step 1: Rule inventory

Read every target file and extract each normative statement (imperatives and value judgments: prefer, avoid, do, don't, never, always, use, write). Build a table:

| ID | Location | Rule (condensed) | Topic |
|---|---|---|---|
| S-01 | SKILL.md:26 | Comments explain why/why not, not what | comments |

- ID prefix per file (S = SKILL.md, RB = ruby.md, RA = rails.md, RS = rust.md, TF = terraform.md, TS = typescript.md).
- Granularity: one row per bullet point or sentence — do not sub-split comma-separated lists.
- Topic tags from a small fixed set, extended as needed: comments, documentation, testing, errors, security, naming, structure, types, dependencies, tooling.
- Favor recall over precision here: when unsure whether a sentence is normative, include it. Filtering happens in Step 2.
- The table is working material, not part of the deliverable — the report includes only per-file counts and the rules cited in findings.

## Step 2: Pairwise judgment

Group the inventory by topic and examine every same-topic pair (within a file and across files). SKILL.md must also be audited against itself — its principle bullets and its dedicated sections can restate each other. Classify each overlapping pair:

- **CONTRADICTION** — following one rule means violating the other, in at least one realistic situation.
- **DUPLICATION** — the same directive stated twice at the same level of abstraction. Drift risk, even if currently consistent.
- **LAYERING (not a finding)** — a general principle plus a language-specific refinement of it. This is the intended structure.

Rules of thumb:

- SKILL.md principle vs. reference-file detail is usually layering — flag it only when the detail restates the principle without adding language-specific substance.
- Overlap **within a single file**, or near-identical text in two reference files, is usually duplication.
- A pair is a contradiction only if you can describe a concrete situation where both rules apply and give different directives. If you cannot, downgrade to duplication or drop it.

## Step 3: Behavioral probe

For the 2–3 topics with the heaviest overlap, write a short code sample (in the relevant language) that the overlapping rules all apply to, and derive what the guide tells you to do. If two rules push the sample in different directions, that confirms a contradiction — record the sample in the finding. If the rules agree on the sample, the pair stays at whatever Step 2 classified it as (usually duplication). Static reading misses conflicts that only appear in application; this step catches them.

## Step 4: Report

Present findings sorted by severity: contradictions, then duplications. For each finding include:

- The rule pair with `file:line` locations and short quotes.
- Why it qualifies (for contradictions: the situation where they conflict, or the probe sample).
- A suggested minimal fix — which copy to keep, or how to reconcile — referencing the guide's own layering structure.

Close with the inventory size (rules extracted per file) so coverage is visible. If nothing is found, say so plainly and still show the inventory size.
