---
name: heroku-cli
description: Use when deploying to Heroku, viewing Heroku logs, scaling dynos, managing Heroku config vars, working with Heroku Postgres, managing Heroku add-ons, enabling Heroku maintenance mode, performing Heroku rollback, creating Heroku apps, or running Heroku commands
---

# Heroku CLI

## Overview

Heroku operations should be fast, scriptable, and verifiable. Use the CLI for all routine operations—use the dashboard only for billing or complex add-on configuration.

**MANDATORY:** Always verify Heroku operations succeeded. Never assume commands worked.

## Iron Laws

- NO APP DESTRUCTION WITHOUT EXPLICIT USER CONFIRMATION
- NO SCALING CHANGES WITHOUT CONFIRMING CURRENT DYNO STATE
- NO CONFIG VAR CHANGES WITHOUT REVIEWING EXISTING VALUES FIRST
- NO MAINTENANCE MODE WITHOUT CONFIRMING WITH USER
- ALWAYS VERIFY HEROKU OPERATIONS SUCCEEDED
- NEVER EXPOSE CONFIG VAR VALUES IN OUTPUT (MAY CONTAIN SECRETS)

## When to Use / Not Use

**Use Heroku CLI for:** Deploying apps, viewing logs, scaling dynos, managing config vars, database operations, release management, maintenance mode, running one-off commands.

**Use dashboard for:** Billing, complex add-on provisioning, access management, pipeline visualization.

## Workflow 1: Deploy an Application

### 1. Pre-check (parallel)

```bash
heroku apps:info -a <app>
git status
git log --oneline -5
```

### 2. Deploy

```bash
# Standard git push deploy
git push heroku main

# Deploy a non-main branch
git push heroku feature-branch:main

# Deploy via container
heroku container:push web -a <app>
heroku container:release web -a <app>
```

### 3. Verify

```bash
heroku releases -a <app> -n 5    # Confirm new release
heroku ps -a <app>               # Check dyno status
heroku logs --tail -a <app>      # Watch for startup errors
```

## Workflow 2: Diagnose and Debug

### 1. Check State

```bash
heroku ps -a <app>               # Dyno status
heroku releases -a <app> -n 5    # Recent releases
heroku config -a <app> -s        # Config vars (shell format, review locally)
```

### 2. View Logs

```bash
heroku logs --tail -a <app>              # All logs, streaming
heroku logs -a <app> -n 500              # Last 500 lines
heroku logs --tail -a <app> --dyno web   # Web dyno only
heroku logs --tail -a <app> --source app # App logs only (exclude router)
```

### 3. Interactive Shell

```bash
heroku run bash -a <app>         # Interactive shell
heroku run rails console -a <app>  # Rails console
heroku run python manage.py shell -a <app>  # Django shell
```

## Workflow 3: Manage Configuration

### 1. Review Current Values

```bash
heroku config -a <app>           # List all config vars
```

> **Warning:** Config vars may contain secrets. Do not log or display values in output.

### 2. Set or Update

```bash
# Set one or more vars (triggers restart)
heroku config:set KEY=value -a <app>
heroku config:set KEY1=val1 KEY2=val2 -a <app>
```

### 3. Remove

```bash
# Confirm with user before removing
heroku config:unset KEY -a <app>
```

### 4. Verify

```bash
heroku config:get KEY -a <app>   # Confirm value set
heroku ps -a <app>               # Confirm dynos restarted
```

## Workflow 4: Scale and Restart

### 1. Check Current State

```bash
heroku ps -a <app>               # Current dyno formation
heroku ps:type -a <app>          # Dyno types and sizes
```

### 2. Scale

```bash
heroku ps:scale web=2 -a <app>           # Scale web to 2 dynos
heroku ps:scale worker=1:standard-2x -a <app>  # Scale with size
heroku ps:scale web=1:standard-1x worker=1:standard-1x -a <app>  # Multiple
```

### 3. Restart

```bash
heroku ps:restart -a <app>       # Restart all dynos
heroku ps:restart web -a <app>   # Restart web dynos only
```

### 4. Verify

```bash
heroku ps -a <app>               # Confirm new formation
```

## Workflow 5: Database Operations

### 1. Check Database Info

```bash
heroku pg:info -a <app>          # Database status and plan
heroku pg:credentials -a <app>   # Connection info
```

### 2. Interactive Query

```bash
heroku pg:psql -a <app>          # Open psql session
```

### 3. Backups

```bash
heroku pg:backups -a <app>                  # List backups
heroku pg:backups:capture -a <app>          # Create backup
heroku pg:backups:download -a <app>         # Download latest
heroku pg:backups:schedule DATABASE --at '02:00 America/New_York' -a <app>
```

### 4. Data Transfer

```bash
# Copy between apps (confirm with user first)
heroku pg:copy <source-app>::DATABASE DATABASE -a <target-app>

# Reset database (DESTRUCTIVE - confirm with user)
heroku pg:reset DATABASE -a <app>
```

## Workflow 6: Releases and Rollback

### 1. Review Release History

```bash
heroku releases -a <app> -n 10  # Last 10 releases
heroku releases:info v42 -a <app>  # Specific release details
```

### 2. Rollback

```bash
# Roll back to previous release
heroku rollback -a <app>

# Roll back to specific version
heroku rollback v42 -a <app>
```

### 3. Verify

```bash
heroku releases -a <app> -n 3   # Confirm rollback release created
heroku ps -a <app>               # Check dyno status
heroku logs --tail -a <app>      # Watch for errors
```

## Workflow 7: Maintenance Mode

### 1. Enable (confirm with user first)

```bash
heroku maintenance:on -a <app>
```

### 2. Perform Work

Run migrations, database changes, or other operations that require downtime.

### 3. Disable

```bash
heroku maintenance:off -a <app>
```

### 4. Verify

```bash
heroku maintenance -a <app>      # Confirm status
heroku ps -a <app>               # Check dynos running
heroku logs --tail -a <app>      # Watch for errors
```

## Safety Protocols

**Never do without explicit user request:**

- `heroku apps:destroy` - Permanent app deletion
- `heroku pg:reset` - Destroys all data
- `heroku pg:copy` - Overwrites target database
- `heroku maintenance:on` - Takes app offline
- `heroku ps:scale web=0` - Stops all web traffic

**Always verify before operations:**

- `heroku apps:info -a <app>` - Confirm correct app
- `heroku ps -a <app>` - Check current state before scaling
- `heroku config -a <app>` - Review vars before changing
- `heroku releases -a <app>` - Check release history before rollback

## Quick Reference

```bash
# Apps
heroku apps:info -a <app>
heroku apps:create <name>
heroku apps:rename <new-name> -a <app>

# Deploy
git push heroku main
heroku container:push web -a <app>
heroku container:release web -a <app>

# Config
heroku config -a <app>
heroku config:set KEY=value -a <app>
heroku config:unset KEY -a <app>

# Dynos
heroku ps -a <app>
heroku ps:scale web=2 -a <app>
heroku ps:restart -a <app>

# Logs
heroku logs --tail -a <app>
heroku logs -a <app> -n 500

# Database
heroku pg:info -a <app>
heroku pg:psql -a <app>
heroku pg:backups:capture -a <app>

# Releases
heroku releases -a <app>
heroku rollback -a <app>

# Maintenance
heroku maintenance:on -a <app>
heroku maintenance:off -a <app>

# One-off Commands
heroku run bash -a <app>
heroku run <command> -a <app>

# Add-ons
heroku addons -a <app>
heroku addons:create <plan> -a <app>
heroku addons:destroy <addon> -a <app>

# Domains
heroku domains -a <app>
heroku domains:add <domain> -a <app>

# Pipelines
heroku pipelines:info <pipeline>
heroku pipelines:promote -a <app>
```

## Key Takeaways

1. **Always specify `-a <app>`** - Avoid relying on git remote detection
2. **Verify every operation** - Check releases, ps, and logs after changes
3. **Review config before changing** - Never blindly set or unset vars
4. **Check dyno state before scaling** - Understand current formation first
5. **Confirm destructive operations** - Destroy, reset, copy need user confirmation
6. **Use maintenance mode for risky changes** - Migrations, major config changes
7. **Watch logs after deploys** - Catch startup errors early

## Additional Resources

See [references/commands.md](references/commands.md) for the full command catalog with flags and options.
