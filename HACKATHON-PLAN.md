# Documentation Automator — Hackathon Plan

**Team:** 5 members (Fabricio + 4)
**Date:** Friday, April 24, 2026
**Repo:** https://github.com/FabricioDevRDC/ai-dev-setup

---

## Problem Statement

Documentation rots because nobody updates it after deploying code. Engineers write great PRs with context, but that knowledge never makes it into Confluence, Dev Portal, READMEs, or Jira. The gap between "code deployed" and "docs updated" is where institutional knowledge goes to die.

## Solution

An **intelligent documentation system** that:
1. **Detects** when a PR is merged or a task is completed
2. **Decides** what type of documentation needs updating (not everything — only what's relevant)
3. **Generates or updates** docs in the right place (Confluence, GitHub README, Dev Portal, Jira)
4. **Uses existing RDC OS tools** — MCPs, skills, and agents already connected to our systems

## Why This Works: What RDC OS Already Gives Us

We don't need to build integrations from scratch. RDC OS Claude Code already has:

| Platform | Read | Write | How |
|----------|------|-------|-----|
| **Confluence** | Search pages, read content, get hierarchy | Create pages, update pages, add comments | Atlassian MCP |
| **Jira** | Get issues, JQL search, metadata | Create issues, edit, comment, transition | Atlassian MCP |
| **Google Docs** | Read text content | Create, write, replace, format | Google Workspace MCP |
| **Google Slides** | Read metadata, thumbnails | Create presentations, add slides | Google Workspace MCP |
| **GitHub** | Read repos, PRs, diffs | Commit, create PRs, comment | `gh` CLI |
| **Dev Portal** | Query ownership, dependencies, tier, health | Read-only (output to other targets) | `/rdc-os:devportal` skill |
| **Glean** | Cross-source search (Confluence, Jira, Slack, GitHub) | Read-only | Glean MCP |
| **New Relic** | NRQL queries, SLOs, alerts | Read-only (output to other targets) | `/rdc-os:observability` skill |
| **SonarCloud** | Quality gates, coverage, code smells | Read-only (output to other targets) | `/rdc-os:quality` skill |

### Key RDC OS Skills We'll Use

| Skill | What it does for us |
|-------|---------------------|
| `/rdc-os:orient` | Generates comprehensive service documentation (ownership, architecture, costs, observability) — the ultimate service README |
| `/rdc-os:architecture` | ADR templates, architecture patterns, Tech Radar compliance |
| `/rdc-os:devportal` | Service metadata, ownership, tier, dependencies, SoundCheck health |
| `/rdc-os:observability` | New Relic monitoring setup, SLOs, error rates — for runbook generation |
| `/rdc-os:quality` | SonarCloud quality gates, coverage — for quality reports |
| `/rdc-os:graphql` | Pantheon subgraph architecture — for API documentation |
| `/rdc-os:pr-standards` | PR template detection, review standards |
| `/rdc-os:report` | Generate narrative reports with charts (HTML/markdown) |
| `/rdc-os:jira` | Jira issue management, linking docs to tickets |

---

## The AI Decision Engine: How It Decides What to Document

This is the core differentiator. The automator doesn't blindly update everything — it classifies the change and routes to the right doc target.

### Classification Matrix

| Change Type | Signals (from PR diff + Jira) | Doc Target | Action |
|-------------|-------------------------------|------------|--------|
| **New feature** | `feat()` commit, new routes/endpoints, new UI components | Confluence + README + Jira | Create feature doc page, update README, comment on Jira |
| **API change** | Modified route handlers, new/changed GraphQL resolvers, schema changes | Confluence API docs + Dev Portal | Update API reference, flag breaking changes |
| **Infrastructure** | Helm charts, Terraform, CloudFormation, Dockerfile changes | Confluence runbook + Architecture ADR | Update deployment runbook, create ADR if architectural |
| **Config change** | New env vars, feature flags, secrets references | Confluence runbook + README | Update config reference section |
| **Bug fix** | `fix()` commit, linked to bug ticket | Jira comment only | Add resolution summary to Jira ticket |
| **Refactor** | `refactor()` commit, no behavioral change | No docs needed | Skip (log decision) |
| **Test only** | `test()` commit, only test files changed | No docs needed | Skip (log decision) |
| **Dependency update** | `chore()` commit, lock file changes | Changelog only | Append to CHANGELOG |

### Decision Flow

```
PR merged → Read diff + title + body + linked Jira ticket
  │
  ├─ Classify change type (feat/fix/refactor/infra/config/test/chore)
  │
  ├─ If type needs docs:
  │   ├─ Search existing docs (Glean + Confluence CQL) for related pages
  │   ├─ If page exists → UPDATE with new info
  │   └─ If no page → CREATE new doc from template
  │
  ├─ If type is skip-worthy:
  │   └─ Log "No docs needed for [type]: [reason]" → done
  │
  └─ Post summary: what was updated, links, and any manual follow-ups needed
```

---

## What We Need to Build Today

### Goal 1: `/auto-docs` Command (Priority: CRITICAL)

The main command that ties everything together.

**Input:** PR number or Jira ticket
**Output:** Documentation created/updated in the right places

**Steps the command follows:**
1. Fetch PR details (`gh pr view`) + diff (`gh pr diff`)
2. Fetch linked Jira ticket (Atlassian MCP `getJiraIssue`)
3. Classify the change using the matrix above
4. Search for existing related docs (Glean MCP `search` + Confluence `searchConfluenceUsingCql`)
5. Generate/update docs in the appropriate target:
   - **Confluence:** Use `createConfluencePage` or `updateConfluencePage`
   - **README:** Edit repo README via `gh` CLI commit
   - **Jira:** Add comment with `addCommentToJiraIssue`
6. Report what was done and provide links

**Deliverable:** `commands/auto-docs.md`

### Goal 2: `/doc-check` Scanner (Priority: HIGH)

Scans a repo/service and reports what documentation is missing or stale.

**What it checks:**
- Does the repo have a README? Is it up to date?
- Does the service have a Confluence page? When was it last updated?
- Are there ADRs for major architectural decisions?
- Does Dev Portal metadata match current state?
- Are runbooks current with deployment setup?
- Is API documentation matching current routes?

**How it checks:**
- Read repo files (README, CLAUDE.md, docs/)
- Query Confluence via CQL for service name
- Query Dev Portal for metadata
- Query Glean for related docs
- Compare last-modified dates vs recent deploy dates

**Deliverable:** `commands/doc-check.md`

### Goal 3: Deploy Detection Trigger (Priority: HIGH)

GitHub Action that runs `/auto-docs` when a PR merges.

**Deliverable:** `.github/workflows/doc-automator.yml`

### Goal 4: Demo & Presentation (Priority: HIGH)

Live demo: merge a PR → docs auto-update in Confluence + README + Jira.

---

## Task Assignments

| # | Task | Owner | Est. | Priority |
|---|------|-------|------|----------|
| 1 | `/auto-docs` — classification engine + Confluence integration | TBD | 3h | CRITICAL |
| 2 | `/auto-docs` — README + Jira comment + Glean search | TBD | 3h | CRITICAL |
| 3 | `/doc-check` — scanner command with multi-source checks | TBD | 2h | HIGH |
| 4 | GitHub Action workflow for deploy detection | TBD | 2h | HIGH |
| 5 | Demo script + presentation + integration testing | Fabricio | 2h | HIGH |

---

## Timeline (Today)

| Time (CST) | Activity |
|------------|----------|
| 12:00 - 12:30 | Kickoff: clone repo, install, review this plan |
| 12:30 - 3:30 | Build phase: everyone on their assigned task |
| 3:30 - 4:30 | Integration: wire it all together, test end-to-end |
| 4:30 - 5:00 | Demo prep + rehearsal |
| 5:00 | Presentations |

---

## Setup Instructions

```bash
# 1. Clone
git clone https://github.com/FabricioDevRDC/ai-dev-setup.git
cd ai-dev-setup

# 2. Install (sets up all 13 commands + hooks)
chmod +x install.sh
./install.sh

# 3. Verify — open Claude Code and test a command
claude
# then type: /standup

# 4. Authenticate MCPs (one-time, in Claude Code)
# Type /mcp → select "atlassian" → OAuth via Okta SSO
# Type /mcp → select "google-workspace" → OAuth

# 5. Create your branch
git checkout -b <your-name>/hackathon/doc-automator
```

## Success Criteria

- [ ] `/auto-docs <PR>` classifies a change and updates the right documentation target
- [ ] Confluence pages are created/updated automatically for feature and infra changes
- [ ] Jira tickets get documentation summary comments on completion
- [ ] README is updated when new features/commands are added
- [ ] `/doc-check` scans a repo and reports documentation gaps
- [ ] GitHub Action triggers doc generation on PR merge
- [ ] Live demo works end-to-end in under 3 minutes

---

## Technical Notes

- Commands are plain `.md` files in `commands/` — the filename becomes the slash command
- To add a command: create `commands/my-command.md`, then `./install.sh --commands`
- The installer copies to `~/.claude/commands/` where Claude Code picks them up
- MCPs require one-time OAuth auth (Atlassian via Okta, Google via browser)
- Glean requires explicit auth via the authenticate tool
- All MCP write operations are in `ask` permission mode (user confirms before writing)

## Existing Commands Reference

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
