# Heroku CLI Command Reference

Full command catalog organized by category. Consult this when the quick reference in SKILL.md is insufficient.

## Apps

```bash
heroku apps                              # List all apps
heroku apps:info -a <app>                # App details (stack, dynos, addons, git URL)
heroku apps:create <name>                # Create new app
heroku apps:create <name> --region eu    # Create in EU region
heroku apps:create --team <team>         # Create under a team
heroku apps:rename <new-name> -a <app>   # Rename app
heroku apps:destroy -a <app>             # DESTRUCTIVE: Delete app permanently
heroku apps:favorites                    # List favorite apps
heroku apps:favorites:add -a <app>       # Add to favorites
heroku apps:stacks -a <app>              # List available stacks
heroku apps:stacks:set heroku-24 -a <app>  # Set stack
heroku apps:transfer <email> -a <app>    # Transfer ownership
```

## Deploy (Git)

```bash
git push heroku main                     # Deploy main branch
git push heroku feature:main             # Deploy non-main branch
heroku builds -a <app>                   # List builds
heroku builds:info -a <app>              # Latest build info
heroku builds:output -a <app>            # Build output/logs
heroku builds:cancel -a <app>            # Cancel running build
```

## Deploy (Container)

```bash
heroku container:login                   # Authenticate Docker
heroku container:push web -a <app>       # Build and push web image
heroku container:push web worker -a <app>  # Push multiple process types
heroku container:release web -a <app>    # Release pushed image
heroku container:rm web -a <app>         # Remove process type image
```

## Config Vars

```bash
heroku config -a <app>                   # List all vars
heroku config -a <app> -s               # Shell format (KEY=value per line)
heroku config -a <app> -j               # JSON format
heroku config:get KEY -a <app>           # Get single var
heroku config:set KEY=value -a <app>     # Set var (triggers restart)
heroku config:set K1=v1 K2=v2 -a <app>  # Set multiple (single restart)
heroku config:unset KEY -a <app>         # Remove var (triggers restart)
heroku config:unset K1 K2 -a <app>      # Remove multiple (single restart)
```

## Process Management (ps)

```bash
heroku ps -a <app>                       # List dynos and status
heroku ps:type -a <app>                  # Dyno types and sizes
heroku ps:scale web=2 -a <app>           # Scale process count
heroku ps:scale web=2:standard-2x -a <app>  # Scale count and size
heroku ps:scale web=1 worker=1 -a <app>  # Scale multiple types
heroku ps:resize web=standard-2x -a <app>  # Resize without scaling
heroku ps:restart -a <app>               # Restart all dynos
heroku ps:restart web -a <app>           # Restart specific type
heroku ps:restart web.1 -a <app>         # Restart specific dyno
heroku ps:stop web.1 -a <app>           # Stop specific dyno
heroku ps:wait -a <app>                  # Wait for dynos to be running
```

## Logs

```bash
heroku logs -a <app>                     # Recent logs (default 100 lines)
heroku logs -a <app> -n 500             # Last 500 lines
heroku logs --tail -a <app>              # Stream logs
heroku logs --tail -a <app> --dyno web   # Filter by dyno type
heroku logs --tail -a <app> --dyno web.1 # Filter by specific dyno
heroku logs --tail -a <app> --source app # App logs only
heroku logs --tail -a <app> --source heroku  # Platform logs only
```

## Postgres (pg)

```bash
# Info
heroku pg -a <app>                       # List databases
heroku pg:info -a <app>                  # Database details
heroku pg:info DATABASE_URL -a <app>     # Specific database
heroku pg:credentials -a <app>           # Connection credentials
heroku pg:diagnose -a <app>              # Performance diagnostics
heroku pg:bloat -a <app>                 # Table and index bloat
heroku pg:outliers -a <app>              # Slow queries
heroku pg:locks -a <app>                 # Active locks
heroku pg:cache-hit-ratio -a <app>       # Cache effectiveness

# Interactive
heroku pg:psql -a <app>                  # Open psql session
heroku pg:psql DATABASE_URL -a <app>     # Connect to specific database

# Backups
heroku pg:backups -a <app>               # List backups
heroku pg:backups:capture -a <app>       # Create backup now
heroku pg:backups:download -a <app>      # Download latest backup
heroku pg:backups:download b001 -a <app> # Download specific backup
heroku pg:backups:info b001 -a <app>     # Backup details
heroku pg:backups:delete b001 -a <app>   # Delete backup
heroku pg:backups:restore b001 -a <app>  # Restore from backup
heroku pg:backups:schedule DATABASE --at '02:00 America/New_York' -a <app>
heroku pg:backups:unschedule DATABASE -a <app>
heroku pg:backups:schedules -a <app>     # List schedules

# Data Transfer
heroku pg:copy <src-app>::DATABASE DATABASE -a <target>  # Copy between apps
heroku pg:pull DATABASE local_db -a <app>   # Pull to local
heroku pg:push local_db DATABASE -a <app>   # Push from local
heroku pg:reset DATABASE -a <app>        # DESTRUCTIVE: Wipe database

# Maintenance
heroku pg:maintenance -a <app>           # Maintenance status
heroku pg:maintenance:run -a <app>       # Run scheduled maintenance
heroku pg:maintenance:window "Sunday 14:30" -a <app>

# Settings
heroku pg:settings -a <app>              # View settings
heroku pg:settings:log-min-duration-statement 2000 -a <app>
heroku pg:settings:log-statement all -a <app>
```

## Add-ons

```bash
heroku addons -a <app>                   # List app add-ons
heroku addons:info <addon> -a <app>      # Add-on details
heroku addons:create <service>:<plan> -a <app>  # Provision add-on
heroku addons:upgrade <addon> <plan> -a <app>   # Upgrade plan
heroku addons:downgrade <addon> <plan> -a <app> # Downgrade plan
heroku addons:destroy <addon> -a <app>   # Remove add-on
heroku addons:open <addon> -a <app>      # Open add-on dashboard
heroku addons:docs <addon> -a <app>      # Open add-on docs
heroku addons:plans <service>            # List plans for a service
```

## Releases

```bash
heroku releases -a <app>                 # List releases
heroku releases -a <app> -n 20          # Last 20 releases
heroku releases:info -a <app>            # Latest release details
heroku releases:info v42 -a <app>        # Specific release
heroku releases:output v42 -a <app>      # Release build output
heroku rollback -a <app>                 # Roll back to previous
heroku rollback v42 -a <app>             # Roll back to specific version
```

## Domains and SSL

```bash
heroku domains -a <app>                  # List domains
heroku domains:info <domain> -a <app>    # Domain details
heroku domains:add <domain> -a <app>     # Add custom domain
heroku domains:remove <domain> -a <app>  # Remove domain
heroku domains:clear -a <app>            # Remove all domains
heroku certs -a <app>                    # List SSL certs
heroku certs:auto -a <app>               # Automated cert management status
heroku certs:auto:enable -a <app>        # Enable ACM
heroku certs:auto:disable -a <app>       # Disable ACM
```

## Pipelines

```bash
heroku pipelines -a <app>                # Show app's pipeline
heroku pipelines:info <pipeline>         # Pipeline details
heroku pipelines:create <name> -a <app>  # Create pipeline
heroku pipelines:add <pipeline> -a <app> --stage production
heroku pipelines:remove -a <app>         # Remove app from pipeline
heroku pipelines:promote -a <app>        # Promote to next stage
heroku pipelines:diff -a <app>           # Diff between stages
heroku reviewapps:enable -a <app>        # Enable review apps
heroku reviewapps:disable -a <app>       # Disable review apps
```

## Redis

```bash
heroku redis -a <app>                    # List Redis instances
heroku redis:info -a <app>               # Redis details
heroku redis:cli -a <app>                # Open redis-cli session
heroku redis:credentials -a <app>        # Connection info
heroku redis:maxmemory <policy> -a <app> # Set eviction policy
heroku redis:maintenance -a <app>        # Maintenance status
heroku redis:promote <addon> -a <app>    # Promote to REDIS_URL
heroku redis:wait -a <app>               # Wait for Redis to be ready
```

## Spaces and Teams

```bash
# Teams
heroku teams                             # List teams
heroku members -t <team>                 # List team members
heroku members:add <email> -t <team> --role member
heroku members:remove <email> -t <team>

# Spaces (Private Spaces)
heroku spaces                            # List spaces
heroku spaces:info <space>               # Space details
heroku spaces:create <name> --team <team> --region us
heroku spaces:destroy <name>             # DESTRUCTIVE: Delete space
```

## Maintenance

```bash
heroku maintenance -a <app>              # Check maintenance status
heroku maintenance:on -a <app>           # Enable maintenance mode
heroku maintenance:off -a <app>          # Disable maintenance mode
```

## Auth and Access

```bash
heroku auth:whoami                       # Current user
heroku auth:token                        # Current auth token
heroku authorizations                    # List OAuth authorizations
heroku authorizations:create --description "CI"  # Create token
heroku access -a <app>                   # List collaborators
heroku access:add <email> -a <app>       # Add collaborator
heroku access:remove <email> -a <app>    # Remove collaborator
heroku access:update <email> -a <app> --permissions deploy
```

## Run (One-off Dynos)

```bash
heroku run <command> -a <app>            # Run command
heroku run bash -a <app>                 # Interactive shell
heroku run:detached <command> -a <app>   # Run in background
heroku run --size=standard-2x <cmd> -a <app>  # Specify dyno size
heroku run --env KEY=val <cmd> -a <app>  # Set env for run
```

## Scheduler

```bash
heroku addons:open scheduler -a <app>    # Open scheduler dashboard
```

## Drains (Log Drains)

```bash
heroku drains -a <app>                   # List log drains
heroku drains:add <url> -a <app>         # Add log drain
heroku drains:remove <id-or-url> -a <app>  # Remove log drain
```

## Features (Labs)

```bash
heroku features -a <app>                 # List features
heroku features:info <feature> -a <app>  # Feature details
heroku features:enable <feature> -a <app>
heroku features:disable <feature> -a <app>
heroku labs -a <app>                     # List lab features
```

## Webhooks

```bash
heroku webhooks -a <app>                 # List webhooks
heroku webhooks:add -a <app> -i api:release -l notify -u <url>
heroku webhooks:remove <id> -a <app>     # Remove webhook
heroku webhooks:deliveries -a <app>      # List deliveries
```
