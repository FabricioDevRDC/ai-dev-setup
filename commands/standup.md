---
model: haiku
---

Generate a daily standup summary from git activity, open PRs, and Jira tickets.

Optional argument: $ARGUMENTS  (number of days back, default: 1. Use 3 for Monday standup)

## Steps

### 1. Determine time window
- Days back: parse `$ARGUMENTS` as a number, default to 1
- If today is Monday, automatically use 3 days (covers the weekend)
- Since date: `date -v-${DAYS}d +%Y-%m-%d` (macOS) or `date -d "${DAYS} days ago" +%Y-%m-%d`

### 2. Gather git activity
```bash
git log \
  --author="$(git config user.name)" \
  --since="${SINCE_DATE}" \
  --oneline \
  --all
```
Group commits by branch/PR. Summarize in plain English — don't list every commit, describe the work done.

### 3. Gather open PRs
```bash
gh pr list --author @me --json number,title,reviewDecision,statusCheckRollup,url \
  --jq '.[] | {number, title, review: .reviewDecision, ci: (.statusCheckRollup // [] | map(.conclusion) | unique)}'
```
Note: which PRs are waiting for review, have CI failures, or are approved and ready to merge.

### 4. Gather Jira activity (if Jira MCP is available)
Search for tickets assigned to the current user that were updated in the time window:
- Moved to Done → "completed" items
- In Progress → "working on" items  
- Blocked → list as blockers

If Jira MCP is unavailable, skip this step silently.

### 5. Identify blockers
A PR is blocked if:
- It has been open for review > 24h with no response
- CI is failing and you're waiting on infra/dependencies
- A Jira ticket is in "Blocked" status

### 6. Output standup

Format it ready to paste into Slack or a standup doc:

```
**Yesterday / Since [date]:**
- [What was done — high level, by feature not by commit]
- ...

**Today:**
- [What you plan to work on — inferred from open tickets/PRs]
- ...

**Blockers:**
- [PR #N waiting for review since X]  ← only if genuinely blocked
- None  ← if no blockers
```

Keep it to 3-6 bullet points total. No commit hashes. Plain language.
