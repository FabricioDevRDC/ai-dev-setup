---
model: haiku
---

Manage an opdev environment (create, sync, logs, shell, delete).

Usage: $ARGUMENTS
  Examples:
    create devzaga                        — create opdev named devzaga on current branch
    create devzaga branch=feature/xyz     — create on a specific branch
    sync devzaga                          — sync local code to opdev
    logs devzaga                          — tail rq worker logs
    logs devzaga web                      — tail web container logs
    shell devzaga                         — get a python shell inside the web container
    restart devzaga                       — reboot the opdev instance
    delete devzaga                        — delete the opdev stack

## Steps

### 1. Parse the action and stack name
Parse `$ARGUMENTS`:
- First word is the action: `create`, `sync`, `logs`, `shell`, `restart`, `delete`
- Second word is the stack name (e.g. `devzaga`)
- Any `key=value` pairs are additional options

If no action is provided, print the usage above and stop.

### 2. Execute the action

#### create
```bash
# Read current branch if no branch= arg provided
BRANCH=$(git branch --show-current)

fab opdev.create:stack_name=<name>,branch=<branch>,dev_database=qa
```

If the create fails with "branch is behind master", automatically rebase and retry:
```bash
git fetch origin
git rebase origin/master
git push --force-with-lease
fab opdev.create:stack_name=<name>,branch=<branch>,dev_database=qa
```

After creation, sync code immediately:
```bash
fab opdev.sync_fs:<name>,client_sync=False,server_sync=True
```

Print the opdev URL: `https://<name>.opdev.opcity.com`

#### sync
```bash
fab opdev.sync_fs:<name>,client_sync=False,server_sync=True
```

After sync, print: "Code synced. Containers are still running with the old code — run `/opdev restart <name>` if you need to pick up the changes."

#### logs
Determine container name first by SSMing and running `docker ps`. Default container: `opcity-rq-1` (rq worker). If `web` arg provided, use `web`.

Print instructions for the user to run (since SSM is interactive):
```
Run in your terminal:
  fab opdev.ssm:<name>
  docker logs --tail 200 --follow opcity-rq-1
```

If you can determine the container name from context, include it directly.

#### shell
Print instructions:
```
Run in your terminal:
  fab opdev.ssm:<name>
  docker exec -it web bash
  python manage.py shell
```

Include any relevant warm-up commands if context suggests them (e.g., resetting Groups API cache).

#### restart
```bash
fab opdev.reboot:<name>
```

Wait for confirmation that it's back up, then sync:
```bash
fab opdev.sync_fs:<name>,client_sync=False,server_sync=True
```

#### delete
```bash
fab opdev.delete:<name>
```

Confirm with the user before deleting.

### 3. Report
Print what was done and the next suggested step.
