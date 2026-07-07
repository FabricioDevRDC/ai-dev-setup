---
model: opus
---

Disposition aged / open AppSec (or pentest) findings by investigating each one against the CURRENT state of the code, then documenting a defensible decision: mitigated, partially mitigated (needs follow-up), or accepted risk. Built from the RDC pentest-disposition workflow (e.g. FIRE-4039).

Input: $ARGUMENTS  (a tracking ticket that groups findings, e.g. FIRE-4039, OR a list of APPSEC ticket IDs, OR a repo + finding description)

## Principle
A finding is only "resolved" if the code proves it. Read the code, don't trust the ticket age. Every disposition must cite evidence (`file:line`, PR, WAF rule, config value).

## Steps

### 1. Gather the findings
Use the Atlassian MCP to fetch the tracking ticket and every linked APPSEC ticket: title, description, affected URLs/endpoints, severity, labels, and any linked PRs. List the concrete findings to disposition.

### 2. For each finding, investigate the current code
Locate the affected code/config in the relevant repo(s) and determine the live state:
- **Is a control already present?** (rate limiter, input validation, auth check, encryption, security header). Grep for it; read the implementation; confirm it's actually applied to the affected endpoint(s), not just defined.
- **Is it mitigated by a compensating control?** Check infra repos too — WAF rules (rate-based, managed rule groups), CloudFront, global request caps, network policy. A pentest "no bot protection" finding may be covered by a WAF rate rule on the ALB.
- **Is remediation in flight?** Search for open/merged PRs and work tickets touching the code.
- **Is the finding still fully live?** If so, scope exactly what's missing.

### 3. Classify each finding
- **Mitigated / Resolved** — control exists (or WAF/compensating control covers it). Cite evidence. Eligible for re-test + close.
- **In remediation** — a PR/work ticket already addresses it. Link it; close on merge.
- **Partially mitigated** — the severe vector is bounded but the specific finding isn't fully closed. Scope the residual gap; this warrants a follow-up work ticket, NOT accepted risk.
- **Accepted risk** — only if genuinely low-risk and impractical to fix; requires explicit owner sign-off.

### 4. Post the dispositions (only after the user confirms)
For each APPSEC ticket, draft a comment with: current-code evidence, the classification, and a recommendation. Also draft a consolidated summary comment on the tracking ticket (a table: finding | age | disposition | evidence). Do NOT transition tickets or create follow-up tickets automatically — propose them and let the user approve. When creating follow-up tickets, mirror the team's work-ticket format and link them to the parent epic and the source APPSEC ticket.

### 5. Output
A table to the user:
```
| Finding | Disposition | Evidence | Next step |
```
Plus the drafted comments (so the user can review before anything is posted), and a short list of proposed follow-up tickets.

## Notes
- Default to "partially mitigated + follow-up ticket" over "accepted risk" unless the user or an owner explicitly accepts.
- If a finding carries a data-security label (e.g. SDRFindings), note it may be double-tracked elsewhere before final close.
