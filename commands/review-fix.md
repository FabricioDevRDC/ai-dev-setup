---
tier: execution
model: sonnet
---

Review all open comments on your own PR, fix the valid ones, and push back on the incorrect ones.

PR branch or number: $ARGUMENTS

## Steps

### 1. Identify the PR
- If `$ARGUMENTS` is a number, use it directly.
- If it's a branch name, run `gh pr list --head "$ARGUMENTS"` to find the PR.
- Run `gh pr view <number> --json number,headRefName,headRefOid,baseRefName,url,author` to get metadata.
- Confirm the PR author is you (current git user). If it's someone else's PR, stop and warn.

### 2. Fetch all open review comments
```bash
gh api repos/{owner}/{repo}/pulls/<number>/comments \
  --jq '[.[] | select(.position != null) | {id, path, line: .original_line, body, diff_hunk, user: .user.login, url: .html_url}]'
```
Also fetch top-level reviews:
```bash
gh api repos/{owner}/{repo}/pulls/<number>/reviews \
  --jq '[.[] | select(.state != "APPROVED") | {id, state, body, user: .user.login}]'
```

### 3. For each comment — decide: fix or push back

Read the actual file at the commented location with the Read tool. Then:

**A — Valid comment (reviewer is right):**
- Make the exact code change with the Edit tool.
- Reply to the comment thread:
  ```bash
  gh api repos/{owner}/{repo}/pulls/<number>/comments/<comment_id>/replies \
    --method POST \
    --field body="<short reply>"
  ```
  Reply tone: short and direct. "Fixed, good catch" or "Done, moved it up." No need for a full sentence if the fix is obvious.

**B — Invalid comment (reviewer misunderstood something):**
- Do NOT change the code.
- Reply with a clear, friendly explanation. Reference the specific reason.
  ```bash
  gh api repos/{owner}/{repo}/pulls/<number>/comments/<comment_id>/replies \
    --method POST \
    --field body="<explanation>"
  ```
  Keep it collaborative. "I think the intent here is X because..." not "Actually you're wrong because...". Cite the existing pattern, spec, or upstream behavior that justifies the current code.

**C — Question or needs context:**
- Reply explaining the intent. Short and clear.

**Tone rules for replies:**
- Write like you're answering a Slack DM, not writing a formal response.
- No em dashes (`--` or `—`). Use commas or just end the sentence.
- Contractions are fine.
- If it's a one-line fix, the reply can be one line.
- Don't start every reply with "Fixed" or "Thanks". Vary it.

### 4. Commit and push all fixes
If any files were changed:
```bash
git add <changed files>
git commit -m "fix(<scope>): address PR review comments"
git push
```
Do NOT amend — new commit so the reviewer can see what changed.

### 5. Summary report

| File | Line | Reviewer | Decision | Action |
|------|------|----------|----------|--------|
| `path/to/file.py` | 42 | reviewer | Fixed | changed X to Y |
| `path/to/other.py` | 17 | reviewer | Pushed back | explained why existing approach is correct |

Print the PR URL.
