---
name: dev-cli
description: How to use the dev CLI and configure dev.yml for any project. Covers all commands, aliases, built-in tasks, dev.yml schema, and common project configurations. Use when helping users set up, configure, or troubleshoot dev CLI usage in their projects.
---

# dev CLI User Guide

`dev` is a CLI tool for development environment management. It automates project setup, runs dev servers, test suites, linters, and manages project lifecycle through a single unified interface.

## Quick Start

```bash
cd my-project
dev init          # Generate a dev.yml (interactive, detects your project)
dev up            # Provision the development environment
dev server        # Start the dev server
dev test          # Run the test suite
```

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `dev init` | `dev i` | Generate a dev.yml for the current project |
| `dev up [TASK]` | `dev u` | Provision the project (all tasks, or just one) |
| `dev build [NAME] [ARGS...]` | `dev b` | Build the project |
| `dev server [NAME] [ARGS...]` | `dev s` | Start the dev server |
| `dev test [NAME] [ARGS...]` | `dev t` | Run the test suite |
| `dev check [NAME] [ARGS...]` | `dev k` | Run linters and static checks |
| `dev console [NAME] [ARGS...]` | `dev c` | Start an interactive console |
| `dev open [TARGET]` | `dev o` | Open a project URL in the browser |
| `dev reset` | `dev r` | Delete local dev state and dependencies |
| `dev --version` | `dev -v` | Print version |

### Subcommands

Every command that has multiple entries supports subcommands — pass the entry name as the first argument:

```bash
dev up bundler          # Run just the bundler task
dev check rubocop       # Run just the rubocop check
dev test e2e            # Run the e2e test subcommand
dev open github         # Open just the github URL
```

### Gating

`dev build`, `dev server`, `dev test`, `dev console`, and custom commands require `dev up` to have been run first. They check for the `.dev/` directory and abort with "Run `dev up` first" if missing.

### Reset

`dev reset` removes `.dev/`, `vendor/bundle/`, `.bundle/`, and `node_modules/`. It does NOT re-provision — run `dev up` afterward when ready.

## dev.yml Schema

Place a `dev.yml` file in your project root.

```yaml
name: my-project                # Project name (used in output)

up:                              # Array of setup tasks (run by dev up)
  - ruby: "3.4.2"               # Install Ruby via rbenv
  - node: "22.0.0"              # Install Node via nodenv
  - bundler                      # Run bundle install (project-local)
  - yarn                         # Run yarn install
  - bun                          # Run bun install
  - env                          # Copy env files from main worktree (worktrees only)
  - mysql                        # Ensure MySQL is running
  - redis                        # Ensure Redis is running
  - claude                       # Ensure Claude desktop app is installed
  - claude-code                  # Ensure Claude Code CLI is installed
  - railsdb            # Run bin/rails db:prepare
  - custom:                      # Shell-based custom task
      name: "copy .env"
      met?: "test -f .env"
      meet: "cp .env.example .env"

build: "bun run build"           # Command for dev build
server: "bin/rails server"       # Command for dev server
test: "bin/rails test"           # Command for dev test
console: "bin/rails console"     # Command for dev console

check:                           # Named linter commands for dev check
  rubocop: "bundle exec rubocop"
  eslint: "yarn eslint ."

open:                            # Named URLs for dev open (github is built-in — no config needed)
  app: "http://127.0.0.1:3000"
  ci: "https://github.com/org/repo/actions"

commands:                        # Custom commands (dev <name>)
  deploy: "scripts/deploy.sh"
  seed: "bin/rails db:seed"
```

### Top-Level Keys

| Key | Type | Required | Description |
|-----|------|----------|-------------|
| `name` | String | no | Project name |
| `up` | Array | no | Tasks for `dev up` |
| `build` | Runnable | no | `dev build` config |
| `server` | Runnable | no | `dev server` config |
| `test` | Runnable | no | `dev test` config |
| `console` | Runnable | no | `dev console` config |
| `check` | Hash[String, String] | no | Name to shell command mapping |
| `open` | Hash[String, String] | no | Name to URL mapping (`github` is built-in — no config needed) |
| `commands` | Hash[String, Runnable] | no | Custom commands (`dev <name>`) |

### Custom Commands

The `commands:` key defines project-specific commands beyond the built-in set. Each entry becomes invocable as `dev <name>`.

**String shorthand:**
```yaml
commands:
  deploy: "scripts/deploy.sh"
  seed: "bin/rails db:seed"
```

**Hash form with subcommands:**
```yaml
commands:
  migrate:
    run: "bin/rails db:migrate"
    env:
      RAILS_ENV: development
    subcommands:
      rollback: "bin/rails db:rollback"    # dev migrate rollback
      status: "bin/rails db:migrate:status" # dev migrate status
```

Custom commands use the same Runnable schema as `build`/`server`/`test`/`console` — they support `run`, `env`, `build_first`, `desc`, and subcommands. They also require `dev up` to have been run first (gated on `.dev/` directory).

### Runnable Schema (build/server/test/console/commands)

A runnable is either a **string shorthand** or a **hash with subcommands**.

**String shorthand:**
```yaml
test: "bin/rails test"
```

**Hash form with subcommands:**
```yaml
test:
  run: "bun run test:unit"           # Base command (dev test)
  env:                                # Optional env vars
    NODE_ENV: test
  build_first: false                  # Run dev build first (default: false)
  desc: "Run unit tests"             # Optional description
  subcommands:
    watch: "bun run test"            # Subcommand: dev test watch
    coverage: "bun run test:coverage"  # Subcommand: dev test coverage
    e2e: "bun run test:e2e"          # Subcommand: dev test e2e
```

**Known keys:** `run`, `env`, `build_first`, `desc`, `implemented`, `subcommands`.

Set `implemented: false` to disable a command (`dev console` will say "not configured").

### Built-in Tasks (for `up:`)

| Task | Arguments | What it does |
|------|-----------|-------------|
| `ruby` | version (optional, falls back to `.ruby-version`) | Installs Ruby via `rbenv install` |
| `node` | version (optional, falls back to `.node-version`) | Installs Node via `nodenv install` |
| `bundler` | none | `bundle config set --local path vendor/bundle` then `bundle install` |
| `yarn` | none | `yarn install` |
| `bun` | none | `bun install` |
| `env` | none | Copies missing env files (`.env`, `.env.local`, `.envrc`, `.env.keys`) from the main git worktree when running inside a git worktree |
| `npm` | none | `npm install` |
| `mysql` | none | Starts MySQL via `brew services start mysql` |
| `redis` | none | Starts Redis via `brew services start redis` |
| `claude` | none | Installs Claude desktop app via `brew install --cask claude` |
| `claude-code` | none | Installs Claude Code CLI via `brew install --cask claude-code` |
| `railsdb` | none | Runs `bin/rails db:prepare` |
| `custom` | `name`, `met?`, `meet` (all required) | Shell-based idempotent task |

Tasks with version arguments accept both forms:
```yaml
- ruby: "3.4.2"     # Explicit version
- ruby               # Reads .ruby-version from project root
```

### Task Ordering

Tasks run in the order listed in `up:`. Homebrew packages required by tasks (rbenv, nodenv, mysql, redis, yarn) are automatically aggregated and installed before any user tasks run.

### Custom Tasks

Custom tasks provide shell-based idempotency. All three fields are required:
- `name` — display label during `dev up`
- `met?` — shell command that exits 0 if already satisfied
- `meet` — shell command to satisfy the dependency

```yaml
up:
  - custom:
      name: "create database config"
      met?: "test -f config/database.yml"
      meet: "cp config/database.yml.example config/database.yml"
  - custom:
      name: "install pre-commit hooks"
      met?: "test -f .git/hooks/pre-commit"
      meet: "cp hooks/pre-commit .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit"
```

## Typical Workflow

```bash
# First time setting up a project
cd my-project
dev init              # Generate dev.yml (or create manually)
dev up                # Install everything

# Daily development
dev server            # Start dev server
dev test              # Run tests
dev check             # Run linters

# Run a single task or check
dev up bundler        # Re-run just bundler
dev check rubocop     # Run just rubocop
dev test e2e          # Run the e2e subcommand

# Start fresh
dev reset             # Wipe local state
dev up                # Re-provision from scratch
```

## Example Configurations

### Ruby on Rails

```yaml
name: my-rails-app

up:
  - ruby: "3.4.2"
  - bundler
  - mysql
  - redis
  - railsdb
  - custom:
      name: "copy .env"
      met?: "test -f .env"
      meet: "cp .env.example .env"

server: "bin/rails server"
test: "bin/rails test"
console: "bin/rails console"

check:
  rubocop: "bundle exec rubocop"

open:
  app: "http://127.0.0.1:3000"
```

### Node.js / TypeScript

```yaml
name: my-node-app

up:
  - node: "22.0.0"
  - yarn

server: "yarn dev"
test: "yarn test"
build: "yarn build"

check:
  eslint: "yarn eslint ."
  tsc: "yarn tsc --noEmit"
```

### Bun Project

```yaml
name: my-bun-app

up:
  - node: "22.0.0"
  - bun

server: "bun run dev"
test: "bun run test"
build: "bun run build"

check:
  lint: "bun run lint"
  typecheck: "bun run typecheck"
```

### Full-Stack (Ruby + Node)

```yaml
name: my-fullstack-app

up:
  - ruby
  - node
  - bundler
  - yarn
  - mysql
  - redis
  - railsdb

server:
  run: "bin/dev"
  desc: "Foreman (Rails + Vite)"

test:
  run: "bin/rails test"
  e2e: "yarn cypress run"

console: "bin/rails console"

check:
  rubocop: "bundle exec rubocop"
  eslint: "yarn eslint ."

open:
  app: "http://127.0.0.1:3000"
  # Note: github is built-in — no open: entry needed for dev open github

commands:
  deploy: "scripts/deploy.sh"
  seed: "bin/rails db:seed"
  migrate:
    run: "bin/rails db:migrate"
    rollback: "bin/rails db:rollback"
    status: "bin/rails db:migrate:status"
```

### AI/ML Project

```yaml
name: my-ai-project

up:
  - node: "22.0.0"
  - bun
  - claude-code
  - custom:
      name: "pull env vars"
      met?: "test -f .env.local"
      meet: "vercel env pull .env.local"

server: "bun run dev"
test: "bun run test"
build: "bun run build"

check:
  lint: "bun run lint"
  typecheck: "bun run typecheck"

open:
  app: "http://127.0.0.1:3000"
  vercel: "https://vercel.com/team/project"
```

### Monorepo with Subcommands

```yaml
name: my-monorepo

up:
  - node: "22.0.0"
  - bun

server:
  run: "bun run dev"
  web: "bun run dev:web"
  api: "bun run dev:api"
  docs: "bun run dev:docs"

test:
  run: "bun run test"
  unit: "bun run test:unit"
  integration: "bun run test:integration"
  e2e: "bun run test:e2e"
  env:
    NODE_ENV: test

build:
  run: "bun run build"
  web: "bun run build:web"
  api: "bun run build:api"

check:
  lint: "bun run lint"
  typecheck: "bun run typecheck"
  format: "bun run format:check"

open:
  app: "http://127.0.0.1:3000"
  api: "http://127.0.0.1:4000"
  docs: "http://127.0.0.1:3001"
```

## Key Concepts

### Idempotent Setup

Every `dev up` task uses a met?/meet pattern: check if already satisfied before taking action. Running `dev up` twice produces the same result. This makes it safe to run anytime.

### Runtime Isolation

The dev CLI runs under the global Ruby but spawns child processes under the project's Ruby/Node version. Environment variables like `RBENV_VERSION` and `PATH` are set correctly so project tools use the right runtime.

### Project-Local Dependencies

`bundler` installs gems to `vendor/bundle` (not system-wide). This ensures `dev reset` can cleanly remove all installed dependencies and `dev up` can re-provision from scratch.
