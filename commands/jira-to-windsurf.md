---
tier: execution
model: sonnet
---

Analyze a Jira ticket and generate a ready-to-execute implementation prompt for Windsurf Cascade.

Jira ticket: $ARGUMENTS

## Steps

### 1. Fetch the ticket
Use the Atlassian MCP tool or `gh` / `curl` to retrieve the Jira issue `$ARGUMENTS`.
- Get: title, description, acceptance criteria, linked tickets, attachments, comments
- If the ticket has a parent epic or linked design doc, fetch those too for extra context

### 2. Explore the codebase for impact zones
Before writing the prompt, do targeted searches to understand *where* the change needs to land:
- Search for related models, endpoints, services, constants, tests
- Check `git log --oneline --all --grep="<ticket_id>"` to see if prior work exists on this ticket
- Identify which files will likely need to be created or modified

### 3. Think through the implementation
Reason step-by-step:
- What is the goal of this ticket?
- What are the constraints (DB schema, API contracts, Kafka topics, feature flags)?
- What is the minimal correct implementation?
- What tests are needed?
- What could go wrong?

### 4. Generate the Windsurf Cascade prompt
Write a single, self-contained implementation prompt. It must be:
- **Actionable**: Cascade should be able to execute it top-to-bottom without asking questions
- **Specific**: include exact file paths, function names, class names found in step 2
- **Ordered**: steps should be in dependency order (models before services, services before endpoints, endpoints before tests)
- **Scoped**: do not include speculative features — only what the ticket requires

Structure the prompt like this:

```
## Task: <ticket title>

**Jira**: <ticket URL>
**Goal**: <one sentence>

### Context
<relevant background — what exists today, what changes>

### Files to modify
- `path/to/file.py` — <why>
- `path/to/test_file.py` — <why>

### Implementation steps

1. <Step 1 with exact details>
2. <Step 2>
...

### Acceptance criteria
- [ ] <criterion from ticket>
- [ ] Tests pass
- [ ] No regressions in related tests
```

### 5. Deliver the prompt
1. Save the generated prompt to `.cascade-task.md` in the project root (overwrite if exists)
2. Copy the prompt to clipboard:
   ```bash
   cat .cascade-task.md | pbcopy
   ```
3. Open the project in Windsurf (if not already open):
   ```bash
   windsurf . &
   ```
4. Tell the user:
   > Prompt copied to clipboard and saved to `.cascade-task.md`.
   > Open Cascade in Windsurf (Cmd+L), paste with Cmd+V, and hit Enter.
   > The prompt is self-contained — Cascade can run it without modification.
