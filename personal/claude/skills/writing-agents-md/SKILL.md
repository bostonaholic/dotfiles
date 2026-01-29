---
name: writing-agents-md
description: >
  Use when creating or updating AGENTS.md files. Provides the agents.md format
  specification and best practices for writing effective guidance for AI coding
  assistants.
---

# Writing AGENTS.md Files

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
