---
name: draft-pr
description: Commit changes in logical units and create a Draft PR assigned to riseshia. Creates a new branch if on the base branch.
user_invocable: true
---

# Draft PR

Commit work in progress and create a Draft PR assigned to riseshia.

## Steps

Follow these steps in order.

### 1. Check current branch

```bash
git branch --show-current
```

If on a base branch (`staging`, `main`, or `master`), **create a new branch first**.

### 2. Create a new branch (only if on base branch)

Choose a branch name based on the changes. Naming convention:

- Bug fix: `fix/<brief-description>`
- New feature: `feature/<brief-description>`
- Refactoring: `refactor/<brief-description>`
- Documentation: `docs/<brief-description>`
- Other: `chore/<brief-description>`

```bash
git checkout -b <branch-name>
```

### 3. Review changes

```bash
git status
git diff
git diff --cached
```

Review both staged and unstaged changes.

### 4. Commit in logical units

Commit changes in logical units.

**Commit guidelines**:
- Group related changes into a single commit
- Separate unrelated changes into distinct commits
- Append the Co-Authored-By trailer below to each commit

**Commit message and PR language**: Use the **repository's primary language** (determined by recent commit messages), not the conversation language. Check with `git log --oneline -10` and match the style.

```bash
git add <specific-files>
git commit -m "$(cat <<'EOF'
<commit message - in the repo's primary language>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

### 5. Push to remote

```bash
git push -u origin <branch-name>
```

### 6. Create Draft PR

Write the PR title and body in the **repository's primary language**.

```bash
gh pr create --draft --assignee riseshia --title "<PR title>" --body "$(cat <<'EOF'
## Summary
- <list of changes>

## Test plan
- [ ] <test items>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### 7. Report result

Display the created PR URL to the user.
