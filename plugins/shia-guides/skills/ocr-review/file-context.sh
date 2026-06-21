#!/usr/bin/env bash
# OCR Review - Per-file review context builder
#
# Composes the complete review input for a single file:
# other changed files list, unified diff, and merged checklist content.
# Output is structured for direct LLM consumption.
#
# Usage: file-context.sh <diff-base> <filepath> <checklist1> [checklist2 ...]
#   diff-base: commit SHA, "--staged", "HEAD", or commit range (a..b)
#   filepath:  path to the file being reviewed
#   checklists: names of checklists to compose (e.g., general ruby rails)
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: file-context.sh <diff-base> <filepath> <checklist1> [checklist2 ...]" >&2
  exit 1
fi

DIFF_BASE="$1"; shift
FILEPATH="$1"; shift
CHECKLISTS=("$@")

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GIT_DIFF="git diff --no-ext-diff --no-textconv --no-color --find-renames"

# --- Other changed files (status-labeled, all files including current) ---
echo "<other_changed_files>"
$GIT_DIFF --name-status $DIFF_BASE 2>/dev/null || true
echo "</other_changed_files>"
echo ""

# --- Current file identification ---
echo "<current_file_path>$FILEPATH</current_file_path>"
echo ""

# --- Unified diff for this file ---
echo "<current_file_diff>"
$GIT_DIFF -U3 $DIFF_BASE -- "$FILEPATH" 2>/dev/null || true
echo "</current_file_diff>"
echo ""

# --- Composed checklist (all applicable rules merged) ---
echo "<review_checklist>"
for cl in "${CHECKLISTS[@]}"; do
  cl_file="$SCRIPT_DIR/checklists/${cl}.md"
  if [[ -f "$cl_file" ]]; then
    cat "$cl_file"
    echo ""
  else
    echo "<!-- checklist not found: $cl -->"
  fi
done
echo "</review_checklist>"
