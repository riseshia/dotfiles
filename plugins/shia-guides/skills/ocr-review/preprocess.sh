#!/usr/bin/env bash
# OCR Review - Deterministic pre-processing
#
# Handles: diff retrieval, file filtering, project detection, checklist routing.
# Outputs a structured manifest for LLM consumption.
#
# Usage: preprocess.sh [options] [diff-target]
#   diff-target: "staged", "HEAD", branch name, commit SHA, or range (a..b)
#                Default: merge-base of main/master branch
#   --include-tests   Include test files in review
#   --help            Show this help
set -euo pipefail

INCLUDE_TESTS=false
DIFF_TARGET=""

for arg in "$@"; do
  case "$arg" in
    --include-tests) INCLUDE_TESTS=true ;;
    --help|-h)
      sed -n '2,/^set /{ /^#/s/^# \?//p }' "$0"
      exit 0 ;;
    *) DIFF_TARGET="$arg" ;;
  esac
done

# --- Diff base resolution ---

default_branch() {
  local ref
  ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null) && {
    echo "${ref#refs/remotes/origin/}"
    return
  }
  for b in main master; do
    git rev-parse --verify "$b" &>/dev/null && echo "$b" && return
  done
  echo "main"
}

if [[ -z "$DIFF_TARGET" ]]; then
  _branch=$(default_branch)
  DIFF_BASE=$(git merge-base "$_branch" HEAD 2>/dev/null || echo HEAD)
  TARGET_LABEL="merge-base($_branch)..HEAD"
elif [[ "$DIFF_TARGET" == "staged" ]]; then
  DIFF_BASE="--staged"
  TARGET_LABEL="staged changes"
elif [[ "$DIFF_TARGET" == "HEAD" || "$DIFF_TARGET" == "head" ]]; then
  DIFF_BASE="HEAD"
  TARGET_LABEL="working tree vs HEAD"
elif [[ "$DIFF_TARGET" == *".."* ]]; then
  DIFF_BASE="$DIFF_TARGET"
  TARGET_LABEL="$DIFF_TARGET"
else
  DIFF_BASE=$(git merge-base "$DIFF_TARGET" HEAD 2>/dev/null || echo "$DIFF_TARGET")
  TARGET_LABEL="merge-base($DIFF_TARGET)..HEAD"
fi

GIT_DIFF="git diff --no-ext-diff --no-textconv --no-color --find-renames"

# --- Gather raw data ---

NAMESTATUS=$($GIT_DIFF --name-status $DIFF_BASE 2>/dev/null || true)
NUMSTAT=$($GIT_DIFF --numstat $DIFF_BASE 2>/dev/null || true)

if [[ -z "$NAMESTATUS" ]]; then
  cat <<EOF
=== OCR REVIEW MANIFEST ===
target: $TARGET_LABEL
diff_cmd_prefix: $GIT_DIFF -U3 $DIFF_BASE
reviewable_count: 0
No changes found.
=== END MANIFEST ===
EOF
  exit 0
fi

# Binary detection from numstat (binary files show "-" for added/deleted)
declare -A BINARY_MAP=()
declare -A STAT_MAP=()
while IFS=$'\t' read -r added deleted fpath rest; do
  [[ -z "$fpath" ]] && continue
  # Handle renames: numstat shows {old => new} or old\tnew
  [[ -n "$rest" ]] && fpath="$rest"
  if [[ "$added" == "-" ]]; then
    BINARY_MAP["$fpath"]=1
  else
    STAT_MAP["$fpath"]="$((added + deleted))"
  fi
done <<< "$NUMSTAT"

# --- Project context detection ---

PROJECTS=()
[[ -f Gemfile ]] && PROJECTS+=(ruby)
{ [[ -f config/application.rb ]] || grep -q "['\"]\?rails['\"]\?" Gemfile 2>/dev/null; } && PROJECTS+=(rails)
[[ -f Cargo.toml ]] && PROJECTS+=(rust)
[[ -f go.mod ]] && PROJECTS+=(go)
if [[ -f package.json ]]; then
  PROJECTS+=(node)
  grep -q '"react"' package.json 2>/dev/null && PROJECTS+=(react)
fi
{ [[ -f requirements.txt ]] || [[ -f pyproject.toml ]]; } && PROJECTS+=(python)
PROJECT_CTX="${PROJECTS[*]:-none}"

# --- Filter functions ---

is_excluded_dir() {
  case "$1" in
    .idea/*|.vscode/*|.svn/*|.git/*|vendor/*|node_modules/*|target/*|\
    .happypack/*|.cachefile/*|_packages/*|rpm/*|pkgs/*|oh_modules/*|\
    __pycache__/*|.mypy_cache/*|.pytest_cache/*|.tox/*|\
    dist/*|.next/*|.nuxt/*|.turbo/*|coverage/*)
      return 0 ;;
  esac
  return 1
}

is_generated() {
  case "$(basename "$1")" in
    package-lock.json|yarn.lock|pnpm-lock.yaml|pnpm-lock.json|\
    Gemfile.lock|Cargo.lock|poetry.lock|Pipfile.lock|composer.lock|go.sum|\
    *.min.js|*.min.css|*.bundle.js|*.chunk.js|\
    *.map|*.snap|*.generated.*)
      return 0 ;;
  esac
  return 1
}

is_test_file() {
  case "$1" in
    */__tests__/*|*/src/test/java/*|*/src/test/*|*/test_helper*) return 0 ;;
  esac
  case "$(basename "$1")" in
    *_test.go|*_spec.rb|*_test.py|test_*.py|*_test.rs|\
    *.test.js|*.test.jsx|*.test.ts|*.test.tsx|\
    *.spec.js|*.spec.jsx|*.spec.ts|*.spec.tsx|\
    *Test.java|*Tests.java|*_test.exs)
      return 0 ;;
  esac
  return 1
}

# --- Checklist routing ---

map_checklists() {
  local fp="$1" ext="${1##*.}" base
  base=$(basename "$fp")
  local cl="general"

  case "$ext" in
    rb)
      cl="$cl ruby"
      [[ " ${PROJECTS[*]} " == *" rails "* ]] && cl="$cl rails"
      [[ "$base" == *_spec.rb ]] && cl="$cl rspec"
      ;;
    rs)            cl="$cl rust" ;;
    ts|tsx|js|jsx) cl="$cl typescript" ;;
    sql)           cl="$cl sql" ;;
    yml|yaml)      cl="$cl config" ;;
    json)  [[ "$base" == package.json ]] && cl="$cl manifests" || cl="$cl config" ;;
    toml)  [[ "$base" == Cargo.toml ]]   && cl="$cl manifests" || cl="$cl config" ;;
    xml)
      case "$fp" in *[Mm]apper*|*[Dd]ao*) cl="$cl sql" ;; esac
      ;;
    properties|gradle) cl="$cl config" ;;
  esac
  echo "$cl"
}

# --- Process file list ---

REVIEW_PATHS=()
REVIEW_META=()     # "status|changed_lines|checklists"
SKIPPED_LINES=()
CHANGED_LINES=()

while IFS=$'\t' read -r status path1 path2; do
  [[ -z "$status" ]] && continue

  case "$status" in
    D)
      CHANGED_LINES+=("D	$path1")
      SKIPPED_LINES+=("$path1	deleted")
      continue ;;
    R*)
      filepath="${path2:-$path1}"
      CHANGED_LINES+=("R	$path1 -> $filepath")
      fstatus="renamed" ;;
    A)
      filepath="$path1"
      CHANGED_LINES+=("A	$filepath")
      fstatus="added" ;;
    M)
      filepath="$path1"
      CHANGED_LINES+=("M	$filepath")
      fstatus="modified" ;;
    *)
      filepath="$path1"
      CHANGED_LINES+=("$status	$filepath")
      fstatus="$status" ;;
  esac

  # Exclusion checks (order matters: cheapest first)
  if [[ -n "${BINARY_MAP[$filepath]+_}" ]]; then
    SKIPPED_LINES+=("$filepath	binary"); continue; fi
  if is_excluded_dir "$filepath"; then
    SKIPPED_LINES+=("$filepath	excluded-dir"); continue; fi
  if is_generated "$filepath"; then
    SKIPPED_LINES+=("$filepath	generated"); continue; fi
  if [[ "$INCLUDE_TESTS" == false ]] && is_test_file "$filepath"; then
    SKIPPED_LINES+=("$filepath	test-file"); continue; fi

  changed="${STAT_MAP[$filepath]:-0}"
  checklists=$(map_checklists "$filepath")

  REVIEW_PATHS+=("$filepath")
  REVIEW_META+=("$fstatus|$changed|$checklists")
done <<< "$NAMESTATUS"

# --- Output manifest ---

RC=${#REVIEW_PATHS[@]}
SC=${#SKIPPED_LINES[@]}

echo "=== OCR REVIEW MANIFEST ==="
echo "target: $TARGET_LABEL"
echo "diff_base: $DIFF_BASE"
echo "project_context: $PROJECT_CTX"
echo "reviewable_count: $RC"
echo "skipped_count: $SC"
echo "include_tests: $INCLUDE_TESTS"
echo ""

if [[ $SC -gt 0 ]]; then
  echo "[SKIPPED]"
  printf '%s\n' "${SKIPPED_LINES[@]}"
  echo ""
fi

echo "[CHANGED FILES]"
printf '%s\n' "${CHANGED_LINES[@]}"
echo ""

if [[ $RC -eq 0 ]]; then
  echo "No reviewable files found."
  echo "=== END MANIFEST ==="
  exit 0
fi

echo "[REVIEW]"
for i in "${!REVIEW_PATHS[@]}"; do
  IFS='|' read -r fstatus changed checklists <<< "${REVIEW_META[$i]}"
  plan_needed="no"
  [[ "$changed" -gt 50 ]] && plan_needed="yes"
  echo "${REVIEW_PATHS[$i]}	$fstatus	$changed	$plan_needed	$checklists"
done
echo ""

echo "=== END MANIFEST ==="
