---
model: sonnet
---

Create a split PR pair from the current staged/unstaged changes.

Ticket/context: $ARGUMENTS

## Strategy

Split PRs into two parts:
1. **Feature branch** — implementation changes only, pointed at `master`
2. **Tests branch** — test changes only, pointed at the feature branch

This keeps reviews focused. Reviewers can approve the logic separately from the tests, and tests can be merged into the feature branch before it lands on master.

## Steps

### 1. Detect changed files
Run `git status` and `git diff --stat HEAD` to identify all modified files.

Classify each file:
- **impl** — production code (not under `tests/`)
- **test** — test code (under `tests/` or named `test_*.py`)

If there are untracked files outside test or impl directories (docs, scripts, etc.), ask the user how to classify them.

### 2. Derive branch names
From `$ARGUMENTS` (e.g. `FIRE-3773` or a short description):
- Feature branch: `{username}/{ticket}/description`
- Tests branch: `{username}/{ticket}/description-tests`

Load `~/.dev-setup-config` to get `GITHUB_USER` for `{username}`.

If the current branch is already named appropriately, reuse it for the feature branch. If `$ARGUMENTS` is empty, infer from recent commit messages or staged file paths.

### 3. Verify working branch
- If on `master` or unrelated branch: create the feature branch
- If already on the feature branch: proceed
- Stash unrelated changes if needed

### 4. Commit impl changes to the feature branch
```bash
git add <impl_files...>
git commit -m "feat(<ticket>): <short description>"
git push -u origin <feature-branch>
```

### 5. Create the tests branch from the feature branch
```bash
git checkout -b <tests-branch>
git add <test_files...>
git commit -m "test(<ticket>): <short description>"
git push -u origin <tests-branch>
```

### 6. Create both PRs

**PR 1 — Feature PR (feature-branch → master):**
```bash
gh pr create \
  --base master \
  --head <feature-branch> \
  --title "feat(<ticket>): <description>" \
  --body "..."
```

**PR 2 — Tests PR (tests-branch → feature-branch):**
```bash
gh pr create \
  --base <feature-branch> \
  --head <tests-branch> \
  --title "test(<ticket>): <description>" \
  --body "..."
```

The tests PR body must reference the feature PR URL.

### 7. Print summary
```
Feature PR:  <URL>  (→ master)
Tests PR:    <URL>  (→ feature-branch)

Merge order:
  1. Merge Tests PR into feature branch once CI passes
  2. Merge Feature PR into master
```

## PR body templates

### Feature PR
```
## Summary
- <what changed>
- <why>

## Jira
<ticket URL>

## Notes for reviewer
Tests are in a separate PR pointed at this branch: <tests-branch>

## Test plan
- [ ] Tests in companion PR pass
- [ ] No regressions in related test files
```

### Tests PR
```
## Summary
- <what tests were added>

## Jira
<ticket URL>

## Depends on
Feature PR: <feature-PR-URL> (this branch is pointed at it)

## Test plan
- [ ] All new tests pass
```
