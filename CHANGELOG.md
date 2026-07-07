# Changelog

## v3.0.0 — Cost optimization + RDC workflow commands

### Cost optimization (the headline)
- **Default model is now `opusplan`** via the Claude settings template — Opus plans, Sonnet executes. Stops every trivial action from running on Opus.
- **Every slash command now pins a model** in frontmatter by weight: `haiku` (mechanical: standup, branch-from-jira, pr-respond, opdev), `sonnet` (execution: test-gen, split-pr, doc-update, review-fix, risk-assessment), `opus` (reasoning: cr, review-pr, review-comment, rca, appsec-disposition, cve-fix, triage-ticket).
- **Fixed dead code:** the `claude-settings.json.template` was never installed. `install.sh` now installs/merges it into `~/.claude/settings.json` non-destructively with `jq` (existing permissions/env preserved; model normalized off plain Opus). New flag `./install.sh --settings`.

### New commands (reflect real RDC workflows)
- `/review-pr <PRs>` — review one or many PRs, return a merge verdict each, and detect duplicate/conflicting/already-merged PRs. Supports parallel subagent review for large fan-outs.
- `/appsec-disposition <ticket>` — investigate aged AppSec/pentest findings against current code and disposition each with `file:line` evidence (mitigated / partial+follow-up / accepted risk).
- `/rca <symptom or PR>` — root-cause a production incident with proven code evidence, judge the in-flight revert, and produce a real fix plan.

### Improvements
- `/cr` now documents the moveinc CR-project field gotchas (required EM/VP, `CAB Required`/`BAU Deployment` must be empty on create, ADF-typed fields, edit-after-create for the rest).
- Fixed `install.sh --update` to detect the repo's default branch (was hardcoded to `main`; repo is on `master`).
- Version/banner bumped to v3.0.0 (README + install banner were out of sync).

---

## v2.1.0 — 2026-04-24 (Hackathon: Documentation Automation)

### New commands
- `/auto-docs` — documentation automation orchestrator. Reads a PR or Jira ticket, classifies the change type, searches existing docs across Confluence/README/DevPortal/Glean, then creates or updates documentation in the right target. Supports `check` mode for scan-only audits.
- `/doc-check` — full documentation gap scanner. Audits all docs across Confluence, GitHub README, Dev Portal, Jira. Reports critical gaps, stale pages, and missing docs with severity ratings (CRITICAL/WARNING/INFO).
- `/doc-update` — targeted documentation updater with modes: `confluence`, `readme`, `runbook`, `adr`, `jira`. Each mode follows the `/cr` pattern: read context, analyze, generate, write to target.

### AI Classification Engine
The `/auto-docs` command classifies changes before deciding what to document:
- `feat()` → Confluence + README + Jira comment
- API changes → Confluence API docs
- Infrastructure → Runbook + ADR
- `fix()` → Jira comment only
- `refactor()`/`test()`/`chore()` → Skip (no docs needed)

### Integrations leveraged
- Atlassian MCP (Confluence read/write, Jira read/write)
- Google Workspace MCP (Google Docs create/update)
- Glean MCP (cross-source documentation search)
- DevPortal (service metadata, ownership, tier)
- GitHub CLI (PR diffs, commits, README updates)

---

## v2.0.0 — 2026-04-23

### New commands
- `/split-pr` — splits staged changes into a feature PR (impl only) and a tests PR (tests only), with both properly linked and merge-order instructions
- `/opdev` — full opdev lifecycle management: create, sync, logs, shell, restart, delete. Auto-rebases if branch is behind master on create.
- `/pr-respond` — drafts and posts replies to all open comments on a PR (inline + top-level)

### Improved commands

**`/review-comment`**
- Now loads all existing review comments and discussions before posting — never duplicates a comment that's already been made
- If an issue is already covered by another reviewer's comment, skips it (or adds context as a reply instead)
- Rewrote tone rules: writes like a teammate, not a code review tool. No em dashes, no formal headers, short prose, contractions OK
- Added approve flow: if no real issues found (or all prior comments resolved), posts an approval with a genuine short message
- Added missing mock detection for Celery jobs and external calls in tests

**`/review-fix`**
- Replies now follow the same human tone rules (short, conversational, no em dashes)
- Varied reply openers so responses don't all start with "Fixed"

### New git hook
- `prepare-commit-msg` — strips `Co-Authored-By:` lines from AI assistants (Claude, Copilot, etc.) from every commit automatically. Installed globally.

### Documentation
- README rewritten as v2 with full command reference table, environment commands, and hook descriptions
- Added CHANGELOG

---

## v1.0.0 — 2026-02-01

Initial release.

### Commands
- `/review-comment` — inline PR review with code suggestions
- `/review-fix` — address review comments on your own PRs
- `/jira-to-windsurf` — generate Windsurf Cascade prompts from Jira tickets
- `/branch-from-jira` — create branches with proper naming from Jira tickets
- `/cr` — generate full Change Requests in Jira
- `/risk-assessment` — generate Risk Assessment tables for CRs
- `/standup` — daily standup from git + Jira + open PRs
- `/test-gen` — generate tests following project patterns

### Git hooks
- `commit-msg` — conventional commit format enforcement
- `pre-push` — branch naming pattern enforcement

### Setup
- Interactive `install.sh` with dependency checks, git config, and global hook installation
- `CLAUDE.md` template generator
