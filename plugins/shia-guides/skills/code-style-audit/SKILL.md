---
name: code-style-audit
description: Audit Claude-authored commits across all repositories Claude has worked in against the code-style guide, reporting violations plus guide defects (missing, dead, or ambiguous rules) the violations reveal. Run on demand from the dotfiles (marketplace) repo.
user-invocable: true
version: 0.1.0
license: CC0-1.0
arguments: optional git rev-range (e.g. "HEAD~20..", "--since='2 weeks ago'"); defaults to everything since the last audit
---

# Code Style Audit

Measure whether Claude-authored code actually followed the code-style guide. The output serves two feedback loops: violations show where generated code fell short, and recurring or unjudgeable violations show where the **guide itself** is defective — a rule that is repeatedly violated is either being ignored or is too ambiguous to apply, and both are actionable.

**Output is a report.** Never modify the audited code or the guide as part of this skill.

## Corpus selection

The audit sweeps every repository Claude has worked in, discovered from local session transcripts — no filesystem-wide scanning, and no need to run the skill in each repo.

**Repo discovery (transcript-based):**

1. List project directories under `~/.claude/projects/`. Directory names encode working paths, but the encoding is lossy — recover the real path from the `cwd` field of a transcript entry. Parse the JSON rather than pattern-matching raw text (transcripts quote arbitrary file contents, including this skill's own examples):

   ```bash
   for d in "$HOME"/.claude/projects/*/; do
     f=$(find "$d" -maxdepth 1 -name '*.jsonl' -print -quit)
     [ -n "$f" ] && jq -r 'select(type=="object" and has("cwd")) | .cwd' "$f" 2>/dev/null | head -1
   done | sort -u
   ```

2. Union with the repos already registered in `~/.claude/code-style-audit.json` (the watermark file doubles as a durable repo registry). Transcripts are cleaned up after a retention period, so a repo audited once must never depend on transcripts to be rediscovered — only never-audited repos need transcript discovery, and those are recent by definition.
3. Keep paths that still exist and are git repositories (`[ -e "$p/.git" ]`); dedupe (several project dirs can map into the same repo).

**Commit selection, per repo:**

- Claude-authored only — `git log --grep='Co-Authored-By: Claude'`.
- Range:
  1. The argument, if given — pass it through to `git log` verbatim (rev-range or `--since`), same range for every repo.
  2. Otherwise the watermark: read `~/.claude/code-style-audit.json` (a map of repo path → last audited commit) and audit `<watermark>..HEAD`.
  3. First audit of a repo (no watermark entry): the last 20 Claude-authored commits in that repo.
- Keep only commits touching files covered by the guide's language table (code-style SKILL.md "Language references"). Repos with nothing remaining drop out; list them in one line of the report.

**Delegation:** audit each surviving repo in its own subagent (parallel), giving it the guide file paths, the repo path, its commit list, and the Judging rules below. Split a repo into batches if it has more than ~15 commits. Merge the reports afterwards.

## Guide resolution

Read the code-style skill's SKILL.md and the reference files for the languages present in the corpus. This skill is meant to run from the dotfiles (marketplace) repo, so prefer the working copy under the current repo (`plugins/shia-guides/skills/code-style/`) if it exists — found guide defects can then be fixed in place; otherwise use the installed plugin's `code-style` directory (sibling of this skill's base directory).

## Judging rules

1. **Scope**: judge only lines each commit adds or changes. Pre-existing code is out of scope.
2. **Existing convention overrides the guide** (per code-style SKILL.md). Before flagging a convention-type rule (configuration access, migration shape, file structure, naming), check whether the flagged pattern already exists in sibling files or earlier history. If it is established repo convention, do not count a violation — record it once under coverage gaps as a systemically unfollowed rule.
3. **Confidence tiers**: CONFIRMED (clear violation) or PLAUSIBLE (arguable). A PLAUSIBLE finding must state the strongest counter-argument. If the counter-argument convincingly defends the code, drop the finding.
4. **Commit messages** are part of the corpus: the information-layers principle says the commit log records Why. An opening rationale paragraph is sufficient — a what-list after it is fine; only flag messages with no rationale at all.
5. **Comment deletion**: silently deleting a why/why-not comment without relocating the information is a PLAUSIBLE finding under the information-layers principle (the rationale now lives nowhere). Translation or refactoring commits are the usual offenders.
6. **Test framework translation**: the guide's testing rules are RSpec-flavored. For Minitest projects map before judging — describe/context/it naming → test method names still state expected behavior; `let`/`let!` → setup blocks and memoized helpers; FactoryBot → fixtures or `Model.create!`. Judge the underlying principle, not the RSpec vocabulary.
7. **Out of scope, always**: rules invisible in a squashed diff — TDD red/green order, PR descriptions, anything requiring the working process rather than the result. List them as not auditable rather than guessing.

## Report format

1. **Verdict** — 2-3 sentences: overall adherence and anything structural (e.g. violations concentrated in one commit type).
2. **Violations** — grouped by repo, sorted by confidence then severity: commit, `file:line` (post-image), rule violated (short quote + source file), offending code (short quote), confidence with counter-argument where applicable.
3. **Guide coverage gaps** — applicability mismatches, systemically unfollowed rules, gray areas the guide does not resolve. These are guide-improvement candidates, not violations.
4. **Per-rule frequency table** — rules with ≥1 violation only.

## Watermark update

After delivering the report, write the newest audited commit hash to `~/.claude/code-style-audit.json` under the repo's absolute path (create the file if missing). Skip the update when an explicit range argument was used for a re-audit of old commits — only advance, never rewind.
