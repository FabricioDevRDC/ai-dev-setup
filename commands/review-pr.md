---
model: opus
---

Review one or more GitHub PRs and return a clear merge verdict per PR. Built for the RDC workflow of "help me review/approve these" — it checks correctness, CI, existing approvals, and — critically — detects duplicate/conflicting PRs so you never approve two PRs solving the same thing.

Input: $ARGUMENTS  (one or more PR references — numbers, URLs, or `owner/repo#N`, space or comma separated. If a repo isn't specified, use the current repo's origin.)

## What this is NOT
This does not post anything to GitHub by itself. It produces verdicts. Approving/merging is a human decision — only run `gh pr review --approve` after the user explicitly says to.

## Steps

### 1. Resolve each PR and its repo
Parse every reference in `$ARGUMENTS`. For each, resolve `owner/repo` and number. If cloned locally, prefer the local checkout for reading code (`git fetch origin <headRef>` first).

### 2. Gather PR facts (per PR)
```bash
gh pr view <N> --repo <owner/repo> --json title,body,author,baseRefName,headRefName,reviewDecision,mergeable,mergeStateStatus,state,files,additions,deletions,reviews,statusCheckRollup
gh pr diff <N> --repo <owner/repo>
```
Note current approvals (`reviews[] | select(.state=="APPROVED")`), review decision, mergeable state, and CI conclusions.

### 3. Read the actual changed code
Don't review from the title. Read the diff and the surrounding code in context. Verify:
- The change does what the title/body claims.
- Referenced helpers/functions/config/deps actually exist on the branch.
- For dependency bumps: the lockfile is updated too, and the pinned version actually resolves the CVE.
- For security fixes: the vulnerable code path is genuinely closed, not just renamed.
- No obvious bug, regression, broken import, or secret committed.

### 4. Duplicate & conflict detection (the RDC-critical step)
When multiple PRs are passed, OR when reviewing security/dependency PRs:
- Compare files touched and the finding/ticket each closes. Flag any two PRs that modify the **same file + same intent** — they will conflict or one is redundant.
- Check whether the fix is **already merged** on the base branch (`git log origin/<base> --oneline -- <file>` and grep for the change). A common RDC failure is a PR that duplicates work someone already landed.
- If a bump edits `package.json`/`pyproject.toml` but NOT the lockfile, flag it — it may not take effect (known RDC gotcha, e.g. dead transitive deps).

### 5. Decide the verdict per PR
Pick exactly one:
- **APPROVE** — correct, CI green (or only unrelated/flaky red), no blockers.
- **APPROVE WITH NITS** — safe to merge; note the non-blocking nits in the approval.
- **REQUEST CHANGES** — a real correctness/security/CI blocker exists.
- **BLOCKED** — cannot merge yet (conflicting, duplicate, depends on another unmerged PR, missing approval it can't get from you).

Do NOT recommend approving a PR that already has enough approvals + is mergeable — say "already good, no action needed" so you don't add noise.

### 6. Output
One block per PR:
```
- **PR #<N> — <title>** (<author>, +adds/-dels)
- **Verdict:** <APPROVE | APPROVE WITH NITS | REQUEST CHANGES | BLOCKED>
- **What it does:** 1-2 lines
- **Findings:** bullets with file:line, or "none"
- **Duplicate/conflict:** <none | conflicts with #M on <file> | already merged in #K | dup of #J>
- **CI / mergeable / approvals:** <status>
```
End with an **Action list**: which PRs to approve now, which to close as duplicates, which need coordination, and (if the user asked) the exact `gh pr review --approve` / `gh pr close` commands to run — but only run them after explicit confirmation.

## Notes
- For a large fan-out (many PRs), review them in parallel using subagents, then synthesize the verdicts here.
- Prefer honesty over politeness: if a fix is a no-op or the CVE isn't actually closed, say so with evidence (file:line).
