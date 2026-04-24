# Documentation Automator — Hackathon Plan

**Team:** 5 members (Fabricio + 4)
**Date:** Friday, April 24, 2026
**Repo:** https://github.com/FabricioDevRDC/ai-dev-setup

---

## Problem Statement

Documentation is scattered across Confluence, Dev Portal, GitHub READMEs, Jira, and Google Docs. Nobody knows where docs live, if they're current, or if they exist at all. After deploying, nobody updates them. Engineers waste time asking "where is the doc for X?" or discovering stale runbooks during incidents.

## Solution

**One command: `/auto-docs`**

Run it in any repo. It figures out everything on its own:
1. **Finds** all existing docs for the current project (Confluence, README, Dev Portal, Jira, Google Docs, Glean)
2. **Analyzes** what changed (from the latest PR, a specific PR, or a Jira ticket)
3. **Decides** what's worth updating — and what's not (using an AI classification engine)
4. **Updates** existing docs or creates new ones in the right place
5. **Reports** what it did, what it skipped, and what needs manual attention

No questions asked. Fire and forget. The engineer runs `/auto-docs` and goes back to coding.

---

## How It Works

### Input Flexibility

```
/auto-docs              → uses the latest merged PR on current branch
/auto-docs 1234         → uses PR #1234
/auto-docs FIRE-3772    → uses Jira ticket, finds linked PR
/auto-docs check        → scan only, don't update anything — just report gaps
```

### The AI Decision Engine

Not every change needs docs. The command classifies the change first:

| Change Type | What Triggers It | What Gets Updated |
|-------------|-----------------|-------------------|
| New feature | `feat()` commit, new endpoints/commands | Confluence + README + Jira comment |
| API change | Route/schema changes | Confluence API docs + README |
| Infrastructure | Helm, Terraform, CI config | Confluence runbook + ADR |
| Config change | New env vars, feature flags | README config section + runbook |
| Bug fix | `fix()` commit | Jira comment only |
| Refactor / tests / deps | `refactor()`, `test()`, `chore()` | **Nothing** — skip with reason |

### Where It Searches for Existing Docs

| Source | How | What It Finds |
|--------|-----|---------------|
| **Confluence** | CQL search via Atlassian MCP | Service pages, API docs, runbooks, ADRs |
| **GitHub** | Read files in repo | README, CHANGELOG, docs/, ARCHITECTURE.md |
| **Dev Portal** | `/rdc-os:devportal` skill | Owner, tier, dependencies, health score |
| **Jira** | Atlassian MCP | Linked tickets, acceptance criteria, context |
| **Glean** | Glean MCP | Cross-source search: Confluence + Jira + Slack + Drive |
| **Google Docs** | Google Workspace MCP | Team documents, design docs, specs |

### What It Can Write To

| Target | Capability | MCP/Tool |
|--------|-----------|----------|
| **Confluence** | Create pages, update pages, add comments | Atlassian MCP (`createConfluencePage`, `updateConfluencePage`) |
| **README.md** | Edit sections surgically | Edit tool + git commit |
| **Jira** | Add documentation summary comments | Atlassian MCP (`addCommentToJiraIssue`) |
| **CHANGELOG.md** | Append entries | Edit tool + git commit |
| **Google Docs** | Create or update documents | Google Workspace MCP (`docs_create`, `docs_writeText`) |

---

## RDC OS Skills We Leverage

These already exist — we don't build them, we use them:

| Skill | What It Gives Us |
|-------|-----------------|
| `/rdc-os:orient` | Full service documentation generation (ownership, architecture, costs, observability) |
| `/rdc-os:devportal` | Service metadata, tier, dependencies, SoundCheck health |
| `/rdc-os:architecture` | ADR templates, Tech Radar, architecture patterns |
| `/rdc-os:observability` | New Relic monitoring data for runbook generation |
| `/rdc-os:quality` | SonarCloud quality metrics for quality reports |
| `/rdc-os:graphql` | Pantheon subgraph info for API documentation |
| `/rdc-os:jira` | Jira ticket management, linking docs to work items |
| `/rdc-os:report` | Narrative reports with charts |

---

## What We Build Today

### Track 1: The `/auto-docs` Command (CRITICAL — 2-3 people)

The single command file: `commands/auto-docs.md`

**Already written.** See `commands/auto-docs.md` in the repo. It covers:
- Context gathering (repo, DevPortal, CLAUDE.md)
- Change detection (PR diff, Jira ticket, commit classification)
- Doc search (Confluence, GitHub, Glean, Google Docs, DevPortal)
- Doc generation/update (Confluence pages, README, Jira comments, CHANGELOG)
- Final report with actions taken, skipped, and suggestions

**What needs testing and refinement:**
- Test with a real merged PR in an existing RDC repo
- Test Confluence page creation and update flow
- Test Jira comment posting
- Test the "check" mode (scan only)
- Tune the classification — make sure it doesn't over-document or under-document

### Track 2: GitHub Action Trigger (HIGH — 1 person)

`.github/workflows/doc-automator.yml` — triggers `/auto-docs` automatically when a PR merges to main.

Options:
- Run Claude Code CLI in the action (if available in CI)
- Post a Slack notification with the command to run
- Create a Jira task to run `/auto-docs`

### Track 3: Demo & Presentation (HIGH — 1 person)

Live demo showing:
1. Engineer merges a PR
2. Runs `/auto-docs` (or it triggers automatically)
3. Show: Confluence page updated, Jira comment added, README edited
4. Run `/auto-docs check` on a repo with stale docs — show the gap report

---

## Task Assignments

| # | Task | Owner | Est. |
|---|------|-------|------|
| 1 | Test `/auto-docs` with real PRs — fix classification edge cases | TBD | 3h |
| 2 | Test `/auto-docs` Confluence write flow — create + update pages | TBD | 2h |
| 3 | Test `/auto-docs check` mode — gap scanner across sources | TBD | 2h |
| 4 | GitHub Action workflow for auto-trigger on merge | TBD | 2h |
| 5 | Demo script + presentation + end-to-end integration | Fabricio | 2h |

---

## Timeline

| Time (CST) | Activity |
|------------|----------|
| 12:00 - 12:30 | Kickoff: clone, install, review this plan + `commands/auto-docs.md` |
| 12:30 - 3:30 | Build & test: everyone on their track |
| 3:30 - 4:30 | Integration: run full end-to-end, fix issues |
| 4:30 - 5:00 | Demo prep + rehearsal |
| 5:00 | Presentations |

---

## Setup

```bash
# 1. Clone
git clone https://github.com/FabricioDevRDC/ai-dev-setup.git
cd ai-dev-setup

# 2. Install all commands + hooks
chmod +x install.sh
./install.sh

# 3. Authenticate MCPs (one-time, inside Claude Code)
# Type /mcp → select "atlassian" → OAuth via Okta SSO
# Type /mcp → select "google-workspace" → OAuth

# 4. Test it
claude
# then type: /auto-docs check

# 5. Branch
git checkout -b <your-name>/hackathon/doc-automator
```

---

## Success Criteria

- [ ] `/auto-docs` on a real merged PR classifies the change correctly
- [ ] Confluence page is created or updated with relevant content
- [ ] Jira ticket gets a documentation summary comment
- [ ] README is surgically updated (not rewritten) for feature changes
- [ ] `/auto-docs check` reports documentation gaps across all sources
- [ ] Trivial changes (refactor, tests, deps) are correctly skipped
- [ ] Live demo works end-to-end in under 3 minutes

---

## Existing Commands (already installed)

| Command | What it does |
|---------|-------------|
| `/review-comment <PR>` | AI code review with inline GitHub comments |
| `/review-fix <PR>` | Fix review comments on your own PR |
| `/pr-respond <PR>` | Draft replies to all open PR comments |
| `/jira-to-windsurf <ticket>` | Generate Windsurf Cascade prompt from Jira |
| `/branch-from-jira <ticket>` | Create named branch + PLAN.md from Jira |
| `/split-pr [ticket]` | Split staged changes into feature + test PRs |
| `/test-gen <file>` | Generate tests matching project patterns |
| `/cr <ticket>` | Generate full Change Request in Jira |
| `/risk-assessment <ticket>` | Generate Risk Assessment table |
| `/standup [days]` | Daily standup from git + PRs + Jira |
| `/opdev <action>` | Manage opdev environments |
