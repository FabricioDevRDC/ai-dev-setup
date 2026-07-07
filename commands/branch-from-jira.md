---
model: haiku
---

Create a properly named branch from a Jira ticket and scaffold the starting context.

Jira ticket: $ARGUMENTS

## Steps

### 1. Fetch the ticket
Use the Atlassian MCP to get: title, description, acceptance criteria, assignee, ticket type (Story/Bug/Task).

If Jira MCP is unavailable, ask the user for the ticket title and type.

### 2. Build the branch name
Load `~/.dev-setup-config` to get BRANCH_PATTERN, GITHUB_USER.

Apply the pattern:
- `{username}` → value of GITHUB_USER
- `{ticket}` → Jira ticket ID in lowercase (e.g. fire-3772)
- `{type}` → map ticket type: Story→feat, Bug→fix, Task→chore, Spike→chore
- `{description}` → slugify the ticket title: lowercase, spaces→hyphens, strip special chars, max 40 chars

Example: `fzacarias/fire-3772/mvip-agent-emit-change`

### 3. Create the branch
```bash
git checkout main 2>/dev/null || git checkout master
git pull origin $(git branch --show-current)
git checkout -b "<branch-name>"
```

### 4. Find impact zones
Search the codebase to identify which files are most likely to change:
- Search for keywords from the ticket title
- Look for related models, services, endpoints, tests
- Check `git log --oneline --all --grep="$TICKET_ID"` for any prior work

### 5. Write a PLAN.md
Create `PLAN.md` in the project root with:

```markdown
# TICKET_ID — Ticket Title

**Branch:** branch-name
**Jira:** ticket-url
**Date:** today

## Goal
One-sentence summary of what needs to be done.

## Files most likely to change
- `path/to/file.py` — reason
- `path/to/test.py` — reason

## Implementation steps
1. Step one
2. Step two
...

## Open questions
- [ ] Question that needs answering before starting
```

### 6. Summary
Print:
- Branch name created
- PLAN.md location
- Suggested first step
- Reminder: "When ready for Windsurf, run /jira-to-windsurf $ARGUMENTS"
