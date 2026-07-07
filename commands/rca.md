---
model: opus
---

Root-cause analysis of a production incident: form a hypothesis, prove it in the code with evidence, decide whether the in-flight revert/rollback is correct, and produce a real fix plan. Built from the RDC incident workflow (e.g. diagnosing a prod Redis CPU spike traced to a rate-limiter key collision).

Input: $ARGUMENTS  (a description of the symptom, and/or a suspect PR/deploy, and/or an incident ticket)

## Principle
Don't stop at the plausible story. Confirm the mechanism in the code with `file:line` evidence before declaring root cause. If a teammate proposed a cause, verify it rather than repeat it.

## Steps

### 1. Establish the symptom & timeline
Capture: what's degraded (metric/dashboard), when it started, and what changed around then (the suspect deploy/PR/merge). Pull the suspect PR diff if one is named:
```bash
gh pr view <N> --repo <owner/repo> --json title,body,files,mergedAt,headRefName
gh pr diff <N> --repo <owner/repo>
```

### 2. Form the hypothesis
State the most likely mechanism linking the change to the symptom in one sentence (e.g. "a shared cache key gets INCR'd on every request, so all traffic collides on one hot key").

### 3. Prove it in the code
Read the actual code path. Verify each link in the chain:
- The exact function/line that produces the bad behavior.
- Why it triggers under production conditions (request shape, content-type, volume, token/refresh cadence, proxy/NAT collapsing identifiers, etc.).
- Whether the failure is isolated (one endpoint/config) or broad.
- Look for secondary/latent bugs in the same code while you're there (e.g. `None`-comparison, stream-consuming reads that break downstream parsing).
Cite `file:line` for each.

### 4. Assess the mitigation in flight
If a revert/rollback is proposed: confirm it cleanly removes the offending change and doesn't drop unrelated work. State plainly whether it's the right call for now.

### 5. Produce the real fix plan
Separate "stabilize now" (revert/rollback) from "fix properly later". The fix plan should address the actual mechanism (and any secondary bugs found), and note what must be true to safely re-land the reverted change.

### 6. Output — a shareable RCA
```
## Root cause
<one paragraph, the proven mechanism with file:line>

## Evidence
- <file:line> — <what it shows>
- ...

## Why it hit prod now
<request shape / volume / config that triggered it>

## Mitigation in flight
<revert/rollback correct? yes/no + why>

## Real fix (to re-land safely)
1. ...

## Secondary issues found
- <latent bug, file:line> (or "none")
```
If the change came from your own approved review, say so honestly — own it in the writeup.

### 7. Document (only after the user confirms)
Offer to post the RCA as a comment on the incident ticket and/or the revert PR, and to open/update a follow-up ticket for the real fix. Don't post or transition anything without explicit confirmation.
