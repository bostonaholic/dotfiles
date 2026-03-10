# Research: AGENTS.md as Single Source of Truth (2026-03-10)

## Problem Statement

Eliminate duplicate project instruction files (CLAUDE.md, GEMINI.md,
.cursorrules) across AI coding tools by using AGENTS.md as the single
source of truth.

## Requirements

- One file for project instructions that all AI tools can read
- No content duplication across tool-specific files
- Strategy applicable to any project, not just dotfiles

## Findings

### The AGENTS.md Standard

AGENTS.md is an open standard stewarded by the Agentic AI Foundation
(Linux Foundation). It defines a plain Markdown file with no required
schema, frontmatter, or sections. Placed at a project's root, it provides
instructions to AI coding agents.

### Cross-Tool Support Matrix

| Tool | Reads AGENTS.md? | Workaround if not |
| ---- | ---------------- | ----------------- |
| OpenAI Codex | Yes (native) | N/A |
| GitHub Copilot | Yes | N/A |
| Cursor | Yes | N/A |
| Windsurf | Yes | N/A |
| OpenCode | Yes (preferred) | N/A |
| Zed | Yes (low priority) | N/A |
| Claude Code | No | Symlink CLAUDE.md to AGENTS.md |
| Gemini CLI | No (opt-in) | Set context.fileName in settings |
| Aider | No | Pass via `--read AGENTS.md` |

### Current Dotfiles Architecture

```text
AGENTS.md              ← source of truth (tool-agnostic project guide)
CLAUDE.md              ← symlink → AGENTS.md
.cursorrules           ← symlink → AGENTS.md
claude/CLAUDE.md       ← separate file (Claude-specific principles)
  └─ symlinked to ~/.claude/CLAUDE.md
```

This is already near-optimal. Claude Code reads both `~/.claude/CLAUDE.md`
(global, Claude-specific) and project-level `CLAUDE.md` (which resolves to
AGENTS.md via symlink).

### Changes Made

Added Gemini CLI configuration to read AGENTS.md instead of GEMINI.md:

```json
{
  "context": {
    "fileName": ["AGENTS.md"]
  }
}
```

File: `gemini/settings.json` → symlinked to `~/.gemini/settings.json`

### General Strategy for Any Project

For any project that needs cross-tool AI instructions:

1. **Create `AGENTS.md`** at project root with all instructions
2. **Symlink `CLAUDE.md`** → `AGENTS.md` (until Claude Code adds native
   support, tracked in issue #6235 with 3,121+ upvotes)
3. **No `GEMINI.md` needed** if users configure Gemini CLI settings
4. **No `.cursorrules` needed** — Cursor reads AGENTS.md natively
5. **No `.windsurfrules` needed** — Windsurf reads AGENTS.md natively

Minimal setup:

```bash
# Create the source of truth
echo "# Project Instructions" > AGENTS.md

# Claude Code workaround (symlink)
ln -s AGENTS.md CLAUDE.md
```

### Global/Home Directory Instructions

No cross-tool standard exists for global instructions yet (issue #91 on
the AGENTS.md repo). Each tool uses its own path:

| Tool | Global path |
| ---- | ----------- |
| Claude Code | `~/.claude/CLAUDE.md` |
| Codex | `~/.codex/AGENTS.md` |
| Gemini CLI | `~/.gemini/GEMINI.md` |
| OpenCode | `~/.config/opencode/AGENTS.md` |

For now, keep tool-specific global files. A future convention may
standardize on `~/.config/agents/AGENTS.md`.

## Open Questions

1. When will Claude Code add native AGENTS.md support? (issue #6235)
2. Will a global `~/.agents/AGENTS.md` standard emerge? (issue #91)

## Recommendations

1. Use AGENTS.md as source of truth in all projects
2. Symlink CLAUDE.md → AGENTS.md until Claude Code adds native support
3. Configure Gemini CLI globally to read AGENTS.md (done)
4. Keep `claude/CLAUDE.md` for Claude-specific principles that don't apply
   to other tools
5. Monitor issue #6235 — when merged, the CLAUDE.md symlink becomes
   unnecessary
