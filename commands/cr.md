---
model: opus
---

Generate a complete Change Request (CR) from a Jira ticket — including Risk Assessment — and create it directly in the CR Jira project.

Input: $ARGUMENTS  (Jira ticket ID, e.g. FIRE-3772)

---

## CR Template (based on moveinc CR project format)

Every CR has these sections in the description:
1. Summary of Change
2. Reason for Change
3. Components involved
4. Dependencies
5. Test/Validation Plan
6. Dependencies Validation
7. Rollback Plan
8. Deployment Steps
9. Configuration Change *(skip if none)*
10. Monitoring and Alerting
11. Communication Plan
12. Approvers
13. Change Window
14. Change Requester

---

## Steps

### 1. Fetch the source ticket
Use the Atlassian MCP (`getJiraIssue`) to fetch `$ARGUMENTS`:
- Title, description, acceptance criteria, components, assignee, linked tickets
- Any linked PRs in the ticket description or remote links

If there's a linked PR, also run:
```bash
gh pr view <PR_NUMBER> --json title,body,files,additions,deletions,headRefName,baseRefName,author
gh pr diff <PR_NUMBER>
```

### 2. Analyze the change
From the ticket + diff, extract:

**Components:** Which services/systems are touched? (e.g. "Opcity MVIP Agent", "VIP Portal API", "Kafka topic X")

**Change type:** Classify as one of:
- Code deployment (EKS/ArgoCD)
- Feature flag / config change
- DB migration
- Infrastructure change
- Kafka schema change
- Mixed

**Dependencies:** What needs to be true before this deploy?
- Other PRs that must be merged first
- Infrastructure setup needed by another team
- Feature flags in other systems
- DB migrations must run before code deploys

**Rollback:** How do you undo this if something goes wrong?
- Can you revert the PR and redeploy? How long does that take?
- Is there a DB migration that can't be rolled back?
- Is there a feature flag you can turn off instead?

**Deployment steps:** The exact ordered steps to ship this.

**Config changes:** Any new env vars, feature flags, secrets, or DB config?

**Monitoring:** What dashboards/alerts tell you it's working? (DataDog, New Relic, CloudWatch)

**Communication channels:** Which Slack channels should be notified? (default: #fire-opcity-eng)

### 3. Generate the Risk Assessment
Apply the scoring matrix:

**Impact (1–5):** 5=prod outage/data loss, 4=major feature broken, 3=partial degradation, 2=minor, 1=negligible
**Probability (1–5):** 5=≥90%, 4=50–89%, 3=10–49%, 2=3–9%, 1=<3%
**Score = Impact × Probability**
- Critical 20–25 → Immediate mitigation required
- High 12–16 → Implement mitigation plan
- Medium 6–10 → Monitor frequently
- Low 1–5 → Accept, monitor periodically

Evaluate risks across: deployment, data integrity, Kafka/events, API contracts, business logic, external dependencies, performance, security, test coverage, config/flags.

### 4. Build the full CR

Compose the CR description using this exact structure:

```
**Summary of Change:**
<One clear paragraph — what is being changed and why>

**Reason for Change:**
<Business or technical justification>

**Components involved:**
<List the systems/services touched>

**Dependencies:**
- <Dependency 1>
- <Dependency 2>

**Test/Validation Plan:**
- <How was this tested? What environments?>
- <What will you validate post-deploy?>

**Dependencies Validation:**
- <How do you confirm each dependency is met before the change window?>

**Rollback Plan:**
- <Step 1>
- <Step 2>
- <Who to contact: @team in Slack>

**Deployment Steps:**
<Ordered steps. If it's a pure code deploy, say so.>

**Configuration Change:**
<List any flag/env/secret/DB config changes, or "None">

**Monitoring and Alerting:**
<Dashboard links or descriptions — DataDog, New Relic, CloudWatch>

**Communication Plan:**
<Slack channels to notify>

**Approvers:**
- <Name 1>
- <Name 2>
- <Name 3>

**Change Window:**
<Proposed date and time, CST>

**Change Requester:**
<Name from git config or Jira assignee>
```

### 5. Determine CR metadata
- **Summary (Jira title):** `[TICKET-ID] <short description of change>`
- **Priority:** Map from Risk Score → Critical=High, High=High, Medium=Medium, Low=Low
- **Change Window:** Propose next available Tuesday or Wednesday 8:00 AM CST (standard deploy window), unless ticket specifies otherwise

### 5b. RDC CR-project field gotchas (learned the hard way — read before creating)
The moveinc CR project (`createJiraIssue` via Atlassian MCP or REST) has a strict create screen. These cause 400s if you get them wrong:
- **Engineering Manager (`customfield_11318`) and Eng VP (`customfield_13932`) are REQUIRED.** VP is a multi-user field (array). If unknown, pull them from a recent CR in the same area (`searchJiraIssuesUsingJql project = CR AND labels = <team>`) and reuse.
- **Do NOT populate `CAB Required` or `BAU Deployment` on create** — a validator rejects the create with "does not match regular expression ^$". They're set later in the workflow.
- **Only the ~17 create-screen fields are accepted at creation.** Severity, Risk Level, Change Window, Rollback URL, PCI/HIPAA/PII, Risk-sheet URL, etc. must be set with a follow-up `editJiraIssue` AFTER the CR exists — sending them on create triggers "over-population of fields".
- **`customfield_13758` (Improvement Type) and `customfield_14154` (Reason for Change) are rich text (ADF), not plain strings** — wrap as `{"type":"doc","version":1,"content":[{"type":"paragraph","content":[{"type":"text","text":"..."}]}]}`.
- **`customfield_16536` (Pull Request link) is ADF too** — pass a `blockCard` node with the PR URL, not a bare string.
- After creation, link the CR back to the source ticket(s) with `createIssueLink` (type `Relates`), and set the remaining fields via `editJiraIssue`.

### 6. Create the CR in Jira
Use the Jira REST API to create the issue in the CR project:

```bash
# Load Jira credentials
JIRA_BASE="https://moveinc.atlassian.net"
JIRA_EMAIL=$(git config --global user.email)

# Read API token from environment or keychain
JIRA_TOKEN="${JIRA_API_TOKEN:-$(security find-generic-password -a "$JIRA_EMAIL" -s "jira-api-token" -w 2>/dev/null)}"

if [[ -z "$JIRA_TOKEN" ]]; then
  echo "⚠️  No JIRA_API_TOKEN found."
  echo "   Set it: export JIRA_API_TOKEN=your_token"
  echo "   Or save to keychain: security add-generic-password -a '$JIRA_EMAIL' -s 'jira-api-token' -w"
  echo ""
  echo "   Falling back to manual copy mode."
  MANUAL_MODE=true
fi

if [[ "$MANUAL_MODE" != "true" ]]; then
  curl -s -X POST "$JIRA_BASE/rest/api/3/issue" \
    -u "$JIRA_EMAIL:$JIRA_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"fields\": {
        \"project\": {\"key\": \"CR\"},
        \"summary\": \"$CR_TITLE\",
        \"issuetype\": {\"name\": \"Change Request\"},
        \"priority\": {\"name\": \"$CR_PRIORITY\"},
        \"labels\": [\"opcity\"],
        \"description\": {
          \"type\": \"doc\",
          \"version\": 1,
          \"content\": [{\"type\": \"paragraph\", \"content\": [{\"type\": \"text\", \"text\": \"$CR_DESCRIPTION_ESCAPED\"}]}]
        }
      }
    }" | python3 -c "import json,sys; r=json.load(sys.stdin); print(f'CR created: $JIRA_BASE/browse/{r[\"key\"]}')" \
    || echo "Failed to create via API — use manual copy below."
fi
```

### 7. Create the Risk Assessment Google Doc (optional)
Ask the user: "Do you want me to create a Google Doc with the Risk Assessment table? (yes/no)"

If yes, use the Google Workspace MCP (`docs_create` + `docs_writeText`) to create:
- Title: `Risk Assessment — TICKET_ID — YYYY-MM-DD`
- Content: the full Risk Assessment table from Step 3
- Return the Google Doc URL

### 8. Final output

Print in this order:

```
─────────────────────────────────────────
  CR GENERATED: [TICKET-ID]
─────────────────────────────────────────

Jira CR:   https://moveinc.atlassian.net/browse/CR-XXXX  (or "copy below")
Risk Doc:  <Google Doc URL or "skipped">

RISK SUMMARY
  Total: N  |  Critical: N  High: N  Medium: N  Low: N
  Highest: RISK-001 (Score: X) — <description>

CHANGE WINDOW
  Proposed: <date and time CST>

NEXT STEPS
  1. Share CR link with approvers: <names>
  2. Notify Slack channels: <channels>
  3. Confirm dependencies are met before change window
─────────────────────────────────────────
```

If manual mode (no API token), also print the full CR description formatted for copy-paste into Jira.
