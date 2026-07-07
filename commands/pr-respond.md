---
model: haiku
---

Read open comments on a PR and draft + post replies as the PR author or as a reviewer.

PR: $ARGUMENTS

## Steps

### 1. Identify the PR
- If `$ARGUMENTS` is a number or URL, use it directly.
- Run `gh pr view <number> --json number,title,url,author` to confirm.

### 2. Fetch all open comments
```bash
# Inline review comments
gh api repos/{owner}/{repo}/pulls/<number>/comments \
  --jq '[.[] | {id, path, line: .original_line, body, user: .user.login, url: .html_url}]'

# Top-level issue comments (general discussion)
gh api repos/{owner}/{repo}/issues/<number>/comments \
  --jq '[.[] | {id, body, user: .user.login, url: .html_url, created_at}]'

# Reviews with a body
gh api repos/{owner}/{repo}/pulls/<number>/reviews \
  --jq '[.[] | select(.body != "") | {id, state, body, user: .user.login}]'
```

### 3. For each open comment, draft a reply

Read the relevant file/context if needed (for inline comments). Then:

- **If it's a question about intent or approach:** explain the reasoning concisely. 1-3 sentences.
- **If it's raising a concern:** acknowledge it and either explain why the current approach is correct, or note that you'll address it.
- **If it's asking for information (testing, context, docs):** provide the actual information.

### 4. Post replies

For inline review comments:
```bash
gh api repos/{owner}/{repo}/pulls/<number>/comments/<comment_id>/replies \
  --method POST \
  --field body="<reply>"
```

For top-level issue comments:
```bash
gh api repos/{owner}/{repo}/issues/<number>/comments \
  --method POST \
  --field body="<reply>"
```

**Tone rules:**
- Write like you're replying to a Slack message. Short, direct, conversational.
- No em dashes. No formal headers. No bullet points for single-point answers.
- Contractions are fine.
- Reference specifics: file names, function names, the exact behavior being asked about.
- If you're pointing to existing code as evidence, name it ("the backfill script in `scripts/unified_web_portal/` already handles this")

### 5. Report
Print a table of what was replied to:

| Reviewer | Comment (truncated) | Reply posted |
|----------|---------------------|--------------|
| ... | ... | yes |

Print the PR URL.
