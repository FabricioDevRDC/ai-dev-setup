---
model: sonnet
---

Generate a Risk Assessment table for a Change Request from a Jira ticket or PR.

Input: $ARGUMENTS  (Jira ticket ID, PR number, or PR URL)

---

## Risk Scoring Reference

**Impact scale (1–5):**
- 5 = Very High — production outage, data loss, revenue impact
- 4 = High — major feature broken, significant user impact
- 3 = Medium — partial degradation, workaround exists
- 2 = Low — minor issue, limited user impact
- 1 = Very Low — cosmetic or negligible

**Probability scale (1–5):**
- 5 = Very High ≥ 90%
- 4 = High 50–89%
- 3 = Medium 10–49%
- 2 = Low 3–9%
- 1 = Very Low < 3%

**Risk Score = Impact × Probability**
- Critical: 20–25 → Immediate mitigation required
- High: 12–16 → Implement mitigation plan, review at every program review
- Medium: 6–10 → Monitor frequently, consider low-cost mitigation
- Low: 1–5 → Accept the risk, monitor periodically

---

## Steps

### 1. Gather context

**If input is a Jira ticket ID:**
- Fetch the ticket via Atlassian MCP: title, description, acceptance criteria, linked PRs, comments, affected services
- Find the associated PR: `gh pr list --search "$ARGUMENTS"` or check Jira PR links

**If input is a PR number or URL:**
- `gh pr view <number> --json title,body,files,baseRefName,headRefName,headRefOid`
- Try to extract the Jira ticket ID from the branch name or PR title and fetch it too

**Always do:**
- `gh pr diff <number>` — read the full diff
- Note: affected files, services, DB migrations, Kafka schemas, feature flags, external APIs

### 2. Identify risks

Analyze the change for every risk category below. Only include a risk if it genuinely applies to this specific change — do not add generic boilerplate risks.

**Categories to evaluate:**

| Category | Questions to ask |
|----------|-----------------|
| Deployment | Can the deploy be rolled back instantly? Is there a DB migration that can't be undone? |
| Data integrity | Does this touch DB schema, data migrations, or data transformations? Could data be corrupted? |
| Kafka / event streaming | Are AVRO schemas changing? Are new topics added? Could consumers break? |
| API contracts | Are endpoints changing signatures? Are clients versioned? Could backwards compatibility break? |
| Business logic | Does this touch lead routing, payment flows, agent assignment, or email delivery? |
| External dependencies | Does this call external services (SendGrid, Licensing API, Subs-Cats)? What if they're down? |
| Performance | N+1 queries? Unindexed columns? Large payload sizes? Memory allocations in hot paths? |
| Security | New endpoints without auth? User input reaching SQL/shell/template? Permission boundaries? |
| Test coverage | Are the changes covered by tests? Are mocks too shallow to catch regressions? |
| Configuration | New env vars, feature flags, or secrets required? Could misconfiguration cause silent failures? |

For **each real risk** identified, assign:
- **ID**: RISK-001, RISK-002, ... (sequential)
- **Date**: today's date (YYYY-MM-DD)
- **Description**: one clear sentence describing the specific risk for this change
- **Impact**: 1–5 with label (e.g. "4 - High")
- **Probability**: 1–5 with label (e.g. "2 - Low")
- **Risk Score**: Impact × Probability
- **Risk Level**: Critical / High / Medium / Low based on score
- **Mitigation/Response Plan**: specific, actionable steps (not generic)
- **Owner**: default to the PR author (get from `gh pr view --json author`), adjust if another team is responsible
- **Status**: Open

### 3. Output the risk table

Print the full table in two formats:

**A — Markdown (for copy-paste):**

```
| ID | Date | Description | Impact | Probability | Risk Score | Risk Level | Mitigation/Response Plan | Owner | Status |
|----|------|-------------|--------|-------------|------------|------------|--------------------------|-------|--------|
| RISK-001 | YYYY-MM-DD | ... | 4 - High | 2 - Low | 8 | Medium | ... | Name | Open |
```

**B — Plain text rows (easy to paste into Google Sheets / Docs table):**

```
RISK-001 | YYYY-MM-DD | <description> | 4 - High | 2 - Low | 8 | Medium | <mitigation> | <owner> | Open
```

### 4. Summary

After the table, print:

```
Total risks: N
  Critical: N
  High: N
  Medium: N
  Low: N

Highest risk: RISK-XXX — <description> (Score: XX)
Recommended action: <based on highest risk level>
```

### 5. Optionally create a Google Doc

Ask the user: "Do you want me to create a Google Doc with this Risk Assessment? (yes/no)"

If yes:
- Use the Google Workspace MCP `docs_create` tool to create a new doc titled "Risk Assessment — <ticket/PR title>"
- Use `docs_writeText` to write the table content
- Share the doc URL with the user
