---
name: writing-agents-md
description: Use when creating or updating AGENTS.md files. Provides the agents.md format specification and best practices for writing effective guidance for AI coding assistants. Also use when generating AGENTS.md from scratch by analyzing a codebase — triggers on "generate AGENTS.md", "init agents", "create AGENTS.md", "analyze codebase for AGENTS.md".
---

# Writing AGENTS.md Files

This skill has two modes:

1. **Format reference** — Use the spec and writing principles below when manually creating or editing AGENTS.md files.
2. **Automated generation** — Follow the generation workflow (§ Generation Workflow) to analyze a codebase and produce a complete AGENTS.md from scratch.

## The Format

AGENTS.md is intentionally flexible—just standard Markdown. No mandatory fields
or rigid structure. Write what an AI coding assistant needs to know.

## Resolution Hierarchy

1. Explicit user prompts override everything
2. Nearest AGENTS.md to edited file wins (for monorepos)
3. Root AGENTS.md applies to whole project

## Standard Sections

Include these sections, tailored to what you discovered:

### Project Overview

What is this? One paragraph max. Include primary language, framework, and purpose.

### Build and Test Commands

```bash
# Install dependencies
npm install

# Run tests
npm test

# Build for production
npm run build
```

Use actual commands from the project. Be specific.

### Code Style

- Formatting tools (prettier, rubocop, etc.)
- Naming conventions observed in the codebase
- File organization patterns
- Import/require conventions

### Architecture

- Key directories and their purposes
- Important abstractions and patterns
- Data flow overview
- Where new code should go

### Testing

- Test framework and runner
- Test file locations and naming
- How to run specific tests
- Coverage expectations if any

### Security Considerations

- Secrets handling (env vars, vaults)
- Input validation patterns
- Authentication/authorization approach
- Areas requiring extra caution

### PR Guidelines

- Branch naming conventions
- Commit message format
- Review requirements
- CI checks that must pass

## Writing Principles

**Be specific, not generic.** Bad: "Follow best practices." Good: "Run `npm test`
before committing. All tests must pass."

**Commands over descriptions.** Show the exact command to run, not prose about
what should happen.

**Reflect reality.** Document what IS, not what should be. If the codebase has
inconsistencies, note them.

**Skip empty sections.** If a project has no security considerations worth
noting, omit that section entirely.

## Anti-Patterns

| Avoid | Why |
| ------- | ----- |
| "Use good coding practices" | Meaningless—be specific |
| Documenting obvious things | Wastes tokens, adds noise |
| Aspirational guidelines | Agents work with what exists |
| Duplicating README | AGENTS.md complements, not copies |

## Monorepo Considerations

For monorepos, consider nested AGENTS.md files in subdirectories with
package-specific guidance. The root AGENTS.md covers shared conventions.

---

## Generation Workflow

When generating an AGENTS.md from scratch, follow these four phases in order.
Use parallel tool calls within each phase where possible.

### Phase 1: Detect Project Infrastructure

Scan the project root for these signals. Read files that exist; skip those that don't.

| Signal | Files to check |
| ------ | -------------- |
| Package manager | `package.json`, `Gemfile`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`, `build.gradle`, `mix.exs`, `composer.json`, `Package.swift` |
| Lock files | `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `bun.lockb`, `Gemfile.lock`, `poetry.lock`, `Cargo.lock`, `go.sum` |
| Test framework | Look for test config: `jest.config.*`, `.rspec`, `pytest.ini`, `setup.cfg [tool:pytest]`, `vitest.config.*`, `phpunit.xml`, `Rakefile` with test tasks |
| Build system | `Makefile`, `Rakefile`, `Justfile`, `turbo.json`, `nx.json`, `webpack.config.*`, `vite.config.*`, `tsconfig.json`, `next.config.*` |
| CI config | `.github/workflows/`, `.circleci/`, `.gitlab-ci.yml`, `Jenkinsfile`, `.travis.yml`, `bitbucket-pipelines.yml` |
| Linters/formatters | `.eslintrc*`, `.prettierrc*`, `.rubocop.yml`, `biome.json`, `.editorconfig`, `rustfmt.toml`, `.golangci.yml` |
| Dev environment | `dev.yml`, `docker-compose.yml`, `Dockerfile`, `.devcontainer/`, `Procfile`, `.tool-versions`, `.ruby-version`, `.node-version`, `.python-version`, `.nvmrc` |

Also run a directory listing (`ls` or Glob `*/`) to capture the top-level directory structure.

**Output of this phase:** A mental inventory of language, package manager, test runner, build tool, linter, CI system, and directory layout.

### Phase 2: Read Existing Documentation

Read these files if they exist (in parallel):

- `README.md` (or `README.*`)
- `CONTRIBUTING.md`
- `CLAUDE.md`
- `AGENTS.md` (if updating rather than creating)
- `docs/` directory listing (scan for architecture docs, ADRs, style guides)
- `CHANGELOG.md` (first ~50 lines for project context)

Extract:
- Project purpose and description
- Stated conventions (commit format, branch naming, PR process)
- Documented architecture decisions
- Anything that should NOT be duplicated but rather complemented

### Phase 3: Sample Key Files for Patterns

Read 3-5 representative source files to detect actual patterns — don't just trust docs.

**Selection strategy:**
1. One file from each major directory (e.g., `src/`, `lib/`, `app/`, `pkg/`)
2. One test file to see test patterns and naming
3. The main entry point (e.g., `src/index.ts`, `lib/main.rb`, `cmd/main.go`, `app.py`)
4. One config/infrastructure file if present (e.g., database config, middleware setup)

**What to observe:**
- Import/require style (relative vs. absolute, barrel files, aliases)
- Naming conventions (camelCase, snake_case, PascalCase for files/functions/classes)
- Export patterns (default vs. named, module.exports vs. ES modules)
- Error handling patterns (exceptions, Result types, error codes)
- Type usage (TypeScript strictness, type annotations, Sorbet, mypy)
- Architectural patterns (MVC, hexagonal, feature-based, layered)
- Comment style and density

### Phase 4: Generate the AGENTS.md

Assemble the file using the standard sections defined above. Apply these rules:

1. **Only include sections with real content.** If the project has no security considerations worth noting, omit the section entirely.
2. **Use actual commands from the project.** Never write `npm test` if the project uses `bun test`. Never write `pytest` if the project uses `python -m pytest`.
3. **Reflect what IS, not what should be.** If naming is inconsistent, say so. If there are known quirks, document them.
4. **Complement, don't duplicate.** If the README already covers installation, reference it rather than copying it. AGENTS.md is for what an AI assistant needs that isn't elsewhere.
5. **Be specific about where new code goes.** This is the single most valuable thing for an AI: "New API routes go in `src/routes/`. New components go in `src/components/[feature]/`."
6. **Include the exact test command for a single file.** Agents need to run individual tests, not just the full suite. E.g., `npx jest path/to/test.ts` or `ruby -Itest test/specific_test.rb`.
7. **Note CI checks that block merge.** If CI runs linting, type checking, or specific test suites, list them so the agent knows what must pass.

### Generation Checklist

Before presenting the generated AGENTS.md, verify:

- [ ] Project overview is one paragraph, not a wall of text
- [ ] All commands are real (copied from package.json scripts, Makefile targets, CI steps)
- [ ] No generic platitudes ("follow best practices", "write clean code")
- [ ] No empty sections or placeholder content
- [ ] Architecture section reflects actual directory structure, not an ideal
- [ ] Test section includes how to run a single test file
- [ ] Monorepo: considered whether nested AGENTS.md files are needed
