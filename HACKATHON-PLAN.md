# Documentation Automator — Hackathon Plan

**Team:** 5 members (Fabricio + 4)
**Date:** Friday, April 24, 2026
**Repo:** https://github.com/FabricioDevRDC/ai-dev-setup

---

## Problem Statement

Documentation is scattered across Confluence, Dev Portal, GitHub READMEs, Jira, and Google Docs. Nobody updates it after deploying. Engineers waste time asking "where is the doc for X?" or discovering stale runbooks during incidents.

## Solution

A set of **AI-powered slash commands** (skills) that follow the same pattern as `/change-request`:

1. **Read** — look at the PR, understand the changes, fetch linked Jira ticket
2. **Decide** — classify the change, determine what docs need updating
3. **Act** — create or update docs in the right place (Confluence, README, Jira, Dev Portal)
4. **Report** — show what was done, what was skipped, and why

Packaged as a **new standalone repo** that can be integrated into RDC OS later.

---

## The `/change-request` Pattern (our model)

The team already has `/cr` as a working example of this exact pattern:

```
/cr FIRE-3772
  │
  ├─ 1. Fetch the Jira ticket (Atlassian MCP)
  ├─ 2. Find linked PR, read the diff (gh CLI)
  ├─ 3. Analyze: components, change type, dependencies, risks
  ├─ 4. Fill out the CR template (all 14 sections)
  ├─ 5. Create the CR in Jira (Atlassian MCP createJiraIssue)
  └─ 6. Report: CR link, risk summary, next steps
```

Every documentation skill follows this same flow — only the **template** and **target** change.

---

## Skills Inventory

### What Already Exists in RDC OS

| RDC OS Skill | What it does | How we use it |
|-------------|-------------|---------------|
| `/rdc-os:orient` | Full service documentation (ownership, architecture, costs, observability) | Base data for any doc generation |
| `/rdc-os:devportal` | Service metadata, tier, dependencies, SoundCheck health | Read service context, check if DevPortal is stale |
| `/rdc-os:architecture` | ADR templates, Tech Radar, architecture patterns | Generate ADRs for architectural changes |
| `/rdc-os:observability` | New Relic NRQL, SLOs, alerts | Generate monitoring sections for runbooks |
| `/rdc-os:quality` | SonarCloud quality gates, coverage | Generate quality reports |
| `/rdc-os:graphql` | Pantheon subgraph info | API documentation for GraphQL services |
| `/rdc-os:jira` | Jira issue management | Read/write Jira tickets |
| `/rdc-os:report` | Narrative reports with charts | Format and present documentation |
| `/rdc-os:pr-standards` | PR template detection | Detect repo documentation patterns |

### MCPs Available (Read + Write)

| Platform | Read | Write | MCP Tool |
|----------|------|-------|----------|
| **Confluence** | `searchConfluenceUsingCql`, `getConfluencePage` | `createConfluencePage`, `updateConfluencePage` | Atlassian MCP |
| **Jira** | `getJiraIssue`, `searchJiraIssuesUsingJql` | `createJiraIssue`, `editJiraIssue`, `addCommentToJiraIssue` | Atlassian MCP |
| **Google Docs** | `docs_getText` | `docs_create`, `docs_writeText`, `docs_replaceText` | Google Workspace MCP |
| **Google Drive** | `drive_search` | `drive_createFolder`, `drive_moveFile` | Google Workspace MCP |
| **Glean** | `search`, `chat`, `read_document` | (read-only) | Glean MCP |
| **GitHub** | `gh pr view`, `gh pr diff` | `gh` commit, PR create | gh CLI |
| **Dev Portal** | Query via skill | (read-only, update via catalog-info.yaml) | `/rdc-os:devportal` |

---

## Skills to Create

Each skill follows the `/cr` pattern: read → classify → act → report.

### Skill 1: `/auto-docs` — The Orchestrator (CRITICAL)

**The main command.** Reads a PR or Jira ticket, classifies the change, and routes to the appropriate doc actions.

```
/auto-docs              → latest merged PR on current branch
/auto-docs 1234         → PR #1234
/auto-docs FIRE-3772    → Jira ticket, finds linked PR
/auto-docs check        → scan only, report gaps, don't update
```

**Steps (following /cr pattern):**
1. **Fetch** — PR details + diff + linked Jira ticket
2. **Classify** — what type of change (feat/fix/infra/config/refactor)
3. **Search** — find ALL existing docs (Confluence, README, Glean, DevPortal, Google Docs)
4. **Decide** — map change type → doc targets using classification matrix
5. **Act** — update or create docs in each target
6. **Report** — summary of actions taken, skipped, and suggestions

**Classification Matrix:**

| Change Type | Signals | Doc Targets |
|-------------|---------|-------------|
| New feature | `feat()`, new routes/commands | Confluence + README + Jira comment |
| API change | Route/schema modifications | Confluence API docs + README |
| Infrastructure | Helm, Terraform, CI, Docker | Confluence runbook + ADR |
| Config change | New env vars, feature flags | README config + Confluence runbook |
| Bug fix | `fix()` commit | Jira comment only |
| Refactor/tests/deps | `refactor()`, `test()`, `chore()` | **Skip** — no docs needed |

**Status:** Already written in `commands/auto-docs.md`. Needs testing and refinement.

### Skill 2: `/doc-check` — Gap Scanner (HIGH)

Scans a repo/service and reports what documentation is missing or stale across all sources. No writes — read-only audit.

```
/doc-check              → scan current repo
/doc-check opcity       → scan by service name
```

**What it checks:**
- Does the repo have a README? When was it last updated?
- Does the service have Confluence pages? Which types? How stale?
- Does DevPortal metadata match current state (owner, tier, description)?
- Are there ADRs for major decisions?
- Is there a runbook? Is it current?
- Are Jira tickets linked to documentation?

**Output:** Gap report with severity (critical / warning / info) and links.

### Skill 3: `/doc-update <target>` — Targeted Updater (MEDIUM)

Update a specific doc target for the current project. For when you know what you want to update.

```
/doc-update confluence    → update/create Confluence service page
/doc-update readme        → update README based on current code
/doc-update runbook       → update/create Confluence runbook
/doc-update adr           → create ADR for recent architectural changes
```

Uses the same data gathering as `/auto-docs` but targets a single output.

---

## Goals (Deliverables)

### 1. New Repo
- [x] Created: https://github.com/FabricioDevRDC/ai-dev-setup
- [ ] Structure supports integration into RDC OS later (skills as .md files)
- [ ] Clean README with setup instructions and skill reference

### 2. Skills
- [ ] `/auto-docs` — orchestrator skill (classify + route + act)
- [ ] `/doc-check` — gap scanner (read-only audit)
- [ ] `/doc-update` — targeted updater (per-target doc generation)

### 3. Tie Skills / Orchestration
- [ ] `/auto-docs` calls sub-skills or reuses their logic
- [ ] Classification engine is reusable across skills
- [ ] All skills use the same project context gathering (repo + DevPortal + Confluence search)

### 4. Generalization
- [ ] Skills work on ANY repo, not just opcity
- [ ] Project context is derived from CLAUDE.md + catalog-info.yaml + DevPortal
- [ ] Confluence space is auto-detected from project metadata
- [ ] Works with or without Jira, with or without Confluence

### 5. Presentation / Demo
- [ ] Live demo: run `/auto-docs` on a real merged PR → show Confluence update + Jira comment
- [ ] Live demo: run `/doc-check` on a repo → show gap report
- [ ] Slide or summary: what exists in RDC OS, what we built, how it integrates

---

## How the AI Decides What to Document

This is the key question the team raised. The answer:

**The AI doesn't guess. It classifies based on signals, then follows rules.**

### Signal Sources (what the AI reads)
1. **Conventional commit type** — `feat()`, `fix()`, `refactor()`, `docs()`, `ci()`, `chore()`
2. **Files changed** — routes? models? config? tests? infra? UI?
3. **PR title and body** — human-written summary of intent
4. **Jira ticket** — acceptance criteria, ticket type (Story, Bug, Task)
5. **Linked tickets** — parent epic, related work

### Decision Rules (when NOT to document)
- `refactor()` / `test()` / `chore()` → **always skip** (no behavioral change)
- `docs()` → **always skip** (human already updated docs)
- `fix()` with no user-facing impact → **Jira comment only**
- Small internal changes (< 10 lines, no new endpoints/config) → **skip**

### Decision Rules (when TO document)
- New endpoint or route → **Confluence API docs + README**
- New env var or feature flag → **README config + Confluence runbook**
- Terraform / Helm / CI changes → **Confluence runbook + consider ADR**
- New feature with Jira Story → **Confluence feature page + README + Jira comment**

### The Key Principle
> **Don't document for documentation's sake.** Only create/update docs that someone would actually look for later. If nobody would ever search for this information, skip it.

---

## Task Assignments

| # | Task | Owner | Est. |
|---|------|-------|------|
| 1 | `/auto-docs` — test with real PRs, fix classification, test Confluence writes | TBD | 3h |
| 2 | `/doc-check` — build gap scanner skill | TBD | 2h |
| 3 | `/doc-update` — build targeted updater (confluence, readme, runbook modes) | TBD | 2h |
| 4 | Generalization — make skills work on any repo, auto-detect project context | TBD | 2h |
| 5 | Demo + presentation + end-to-end integration | Fabricio | 2h |

---

## Timeline

| Time (CST) | Activity |
|------------|----------|
| 12:00 - 12:30 | Kickoff: clone, install, review this plan |
| 12:30 - 3:30 | Build & test: everyone on their task |
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
# /mcp → select "atlassian" → OAuth via Okta SSO
# /mcp → select "google-workspace" → OAuth

# 4. Test
claude
# type: /auto-docs check

# 5. Branch
git checkout -b <your-name>/hackathon/doc-automator
```

---

## Success Criteria

- [ ] `/auto-docs` on a real merged PR classifies correctly and updates Confluence + Jira
- [ ] `/auto-docs` on a refactor/test PR correctly SKIPs with reason
- [ ] `/doc-check` reports documentation gaps across Confluence, README, DevPortal
- [ ] Skills work on repos other than opcity (generalized)
- [ ] Live demo works end-to-end in under 3 minutes
- [ ] Path to RDC OS integration is clear (skills as .md files, standard patterns)

---

## Existing Commands Reference

| Command | Pattern | Target |
|---------|---------|--------|
| `/cr <ticket>` | Read Jira → analyze PR → fill CR template → create in Jira | Jira CR project |
| `/review-comment <PR>` | Read PR diff → find issues → post inline comments | GitHub PR |
| `/risk-assessment <ticket>` | Read Jira → analyze risks → generate table | Google Doc / stdout |
| `/standup [days]` | Read git + PRs + Jira → generate summary | stdout (paste to Slack) |
| `/auto-docs <PR or ticket>` | **Read PR → classify → update docs everywhere** | **Confluence + README + Jira** |
| `/doc-check` | **Scan all sources → report gaps** | **stdout (audit report)** |
| `/doc-update <target>` | **Read context → update specific doc** | **Confluence / README / runbook** |
