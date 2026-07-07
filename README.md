# ai-dev-setup v3.0

Automated developer environment setup for RDC engineers who use Claude Code + Windsurf/Cursor. One script to configure git conventions, install AI slash commands, apply cost-optimized Claude settings, and enforce team standards across all your projects.

## Cost optimization (v3.0)

Setup now installs a **cost-efficient Claude Code config** so you don't burn Opus credits on everything:

- **Default model: `opusplan`** — Opus does the planning/reasoning, Sonnet executes the steps. Keeps Opus quality where it matters (architecture, review, RCA) and cuts the cost of step execution.
- **Per-command models** — every slash command pins its own model in frontmatter: `haiku` for mechanical commands (`/standup`, `/branch-from-jira`), `sonnet` for execution (`/test-gen`, `/split-pr`, `/doc-update`), `opus` for reasoning-heavy ones (`/cr`, `/review-pr`, `/rca`, `/cve-fix`).
- Applied non-destructively — merges into your existing `~/.claude/settings.json` with `jq` (your permissions/env are preserved; only the model default is normalized off plain Opus). Re-run anytime with `./install.sh --settings`.

## Quick Start

```bash
git clone https://github.com/FabricioDevRDC/ai-dev-setup.git
cd ai-dev-setup
chmod +x install.sh
./install.sh
```

---

## Commands

After setup, these slash commands are available in Claude Code in any project:

### Code Review

| Command | What it does |
|---------|-------------|
| `/review-pr <PRs>` | Reviews one or many PRs and returns a merge verdict each (APPROVE / REQUEST CHANGES / BLOCKED). Reads the real diff, checks CI + existing approvals, and **detects duplicate/conflicting PRs and already-merged fixes** so you never approve two PRs solving the same thing. Does not post anything without your go-ahead. |
| `/review-comment <PR>` | Reviews a PR diff and posts inline GitHub comments. Checks existing discussions first so it never duplicates. Writes like a teammate, not a bot. |
| `/review-fix <PR>` | Reads open review comments on your own PR, fixes the valid ones, pushes back with reasoning on incorrect ones, and commits. |
| `/pr-respond <PR>` | Drafts and posts replies to all open comments on a PR — questions, concerns, or requests for context. |

### Implementation

| Command | What it does |
|---------|-------------|
| `/jira-to-windsurf <ticket>` | Analyzes a Jira ticket + codebase and generates a ready-to-run prompt for Windsurf Cascade. Saves to `.cascade-task.md` and copies to clipboard. |
| `/branch-from-jira <ticket>` | Creates a properly named branch and writes a `PLAN.md` with impact zones and implementation steps. |
| `/split-pr [ticket]` | Splits staged changes into a feature PR (impl only) and a tests PR (tests only), both properly linked. |
| `/test-gen <file or function>` | Generates tests following the project's exact patterns, fixtures, and mock style. |

### Planning & Delivery

| Command | What it does |
|---------|-------------|
| `/cr <ticket>` | Generates a complete Change Request in Jira (all sections + Risk Assessment) from a ticket ID. Documents the CR-project field gotchas (required EM/VP, CAB/BAU-must-be-empty-on-create, ADF fields). |
| `/risk-assessment <ticket or PR>` | Generates a standalone Risk Assessment table for a Change Request. |
| `/appsec-disposition <ticket>` | Investigates aged/open AppSec or pentest findings against the current code and dispositions each (mitigated / partial+follow-up / accepted risk) with `file:line` evidence. Drafts the Jira comments; posts only on your confirmation. |
| `/rca <symptom or PR>` | Root-causes a production incident — proves the mechanism in code with evidence, judges whether the in-flight revert is correct, and produces a real fix plan + shareable RCA writeup. |
| `/standup [days]` | Generates a standup summary from git, PRs, and Jira activity. Defaults to 1 day; use 3 for Monday. |

### Documentation Automation (NEW — Hackathon)

| Command | What it does |
|---------|-------------|
| `/auto-docs <PR or ticket>` | Reads a PR or Jira ticket, classifies the change, searches for existing docs across Confluence/README/DevPortal/Glean, then creates or updates documentation in the right place. Fire and forget. |
| `/auto-docs check` | Scan-only mode — reports what docs exist and what's missing without changing anything. |
| `/doc-check` | Full documentation gap audit. Scans Confluence, README, Dev Portal, Jira, and in-repo docs. Reports critical gaps, stale pages, and missing docs with severity ratings. |
| `/doc-update confluence` | Creates or updates the Confluence service overview page for the current project. |
| `/doc-update readme` | Updates the repo README based on current code state. Surgical edits, not rewrites. |
| `/doc-update runbook` | Creates or updates the Confluence deployment/operations runbook. |
| `/doc-update adr` | Creates an Architecture Decision Record for recent architectural changes. |
| `/doc-update jira` | Adds documentation summary comments to recent completed Jira tickets. |

### Environments

| Command | What it does |
|---------|-------------|
| `/opdev create <name>` | Creates a new opdev environment on your current branch. Auto-rebases if behind master. |
| `/opdev sync <name>` | Syncs local server code to an opdev. |
| `/opdev logs <name>` | Prints the docker logs commands for the rq worker or web container. |
| `/opdev shell <name>` | Prints the SSM + docker exec commands to get a python shell inside the opdev. |
| `/opdev restart <name>` | Reboots the opdev EC2 instance and re-syncs code. |
| `/opdev delete <name>` | Deletes the opdev stack (asks for confirmation first). |

---

## Git Hooks

Three hooks are installed globally (apply to all repos) or per-project.

### `commit-msg` — Conventional Commits
Validates every commit against `type(scope): subject` format.

```bash
git commit -m "feat(auth): add OAuth2 login"   # ✓
git commit -m "updated stuff"                   # ✗ blocked
```

Allowed types: `feat`, `fix`, `test`, `refactor`, `chore`, `docs`, `ci`, `perf`, `build`, `revert`

### `pre-push` — Branch naming
Validates branch names against your configured pattern before push.

Default pattern: `{username}/{ticket}/{description}`

```bash
fzacarias/FIRE-3772/mvip-agent-emit-change   # ✓
my-feature                                   # ✗ blocked
```

### `prepare-commit-msg` — Strip AI co-author attribution
Automatically removes `Co-Authored-By:` lines from any AI assistant (Claude, Copilot, etc.) so commits only show the real author.

---

## Install Flags

```bash
./install.sh              # Full interactive setup
./install.sh --check      # Check tool dependencies only
./install.sh --configure  # Re-run configuration wizard
./install.sh --settings   # Install/merge cost-optimized Claude settings (opusplan)
./install.sh --commands   # Install/update Claude commands only
./install.sh --hooks      # Install git hooks in the current repo
./install.sh --update     # Pull latest and reinstall commands
./install.sh --claude-md  # Generate a CLAUDE.md template in the current project
```

---

## Configuration

Preferences are saved to `~/.dev-setup-config`. Edit directly or re-run `./install.sh --configure`.

```bash
GIT_NAME="Fabricio Zacarias"
GIT_EMAIL="fabricio@example.com"
GITHUB_USER="FabricioZAGA"
AI_EDITOR="windsurf"
USE_JIRA="true"
JIRA_WORKSPACE="yourteam.atlassian.net"
BRANCH_PATTERN="{username}/{ticket}/{description}"
USE_CONVENTIONAL_COMMITS="true"
```

---

## Requirements

**Required:** git ≥ 2.30, gh CLI ≥ 2.0, Node.js ≥ 18, Claude Code

**Optional:** Windsurf or Cursor, Jira Atlassian MCP, Google Workspace MCP, Glean MCP, jq

---

## Adding Your Own Commands

Commands are plain `.md` files in `commands/`. The filename becomes the slash command name.

```bash
cat > commands/my-command.md << 'EOF'
Do something useful with: $ARGUMENTS
## Steps
1. ...
EOF
./install.sh --commands
```

---

## Updating

```bash
cd ai-dev-setup
./install.sh --update
```

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

*Built by [@FabricioDevRDC](https://github.com/FabricioDevRDC)*
