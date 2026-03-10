# Research: Cross-Compatible Skills for Claude Code and Gemini CLI (2026-03-10)

## Problem Statement

Make all 39 Claude Code skills in `claude/skills/` accessible from Google
Gemini CLI using dual-compatible files - a single set of skill files that
both tools can read natively.

## Requirements

- Same SKILL.md files must work in both Claude Code and Gemini CLI
- All 39 existing skills should be available
- Solution must integrate with the dotfiles.yaml symlink workflow
- No changes to the actual skill content should be needed

## Findings

### Format Compatibility: Identical

Both Claude Code and Gemini CLI implement the **Agent Skills open standard**
([agentskills.io](https://agentskills.io)). The SKILL.md format is the same:

```yaml
---
name: skill-name
description: >-
  What this skill does and when to use it.
---

# Markdown body with instructions
```

The existing skills (e.g., `git-commit`, `bat`, `beads`) already conform to
the spec. **No content changes are needed.**

### Discovery Paths: The Only Difference

| Tool       | Scans These Paths                                        |
| ---------- | -------------------------------------------------------- |
| Claude Code | `~/.claude/skills/`, `~/.agents/skills/`, `.claude/skills/`, `.agents/skills/` |
| Gemini CLI | `~/.gemini/skills/`, `~/.agents/skills/`, `.gemini/skills/`, `.agents/skills/` |

The **cross-client interoperability path** is `~/.agents/skills/` (user-level)
and `.agents/skills/` (project-level). Both tools scan this location.

### Current Setup

```text
dotfiles/claude/skills/ → symlinked to → ~/.claude/skills/
```

Claude Code finds skills. Gemini CLI does not, because it doesn't scan
`~/.claude/skills/`.

### Relevant Files

| File | Purpose | Key Lines |
| ---- | ------- | --------- |
| `dotfiles.yaml` | Symlink definitions | 23 |
| `claude/skills/*/SKILL.md` | 39 skill definitions | all |
| `claude/settings.json` | Claude Code config | 80-91 |

### Skill Inventory (39 skills)

**Categories:**

- **CLI tools** (12): bat, btop, dua, duf, eza, fd, gping, jq, lazygit,
  ports, ripgrep, tldr
- **Development workflow** (8): bare-worktrees, bash-script-quality,
  dependency-analysis, gh-cli, git-commit, pr-verification, beads,
  test-driven-bug-fix
- **Frameworks** (5): rails-8, rails-conventions,
  vercel-react-best-practices, vercel-composition-patterns,
  simplifying-ruby-code
- **Documentation** (6): mermaid, product-requirements-doc,
  technical-design-doc, web-design-guidelines, writing-agents-md,
  writing-prose
- **Analysis** (4): project-context-discovery, react-doctor,
  refactoring-to-patterns, security-analysis
- **Infrastructure** (2): heroku-cli, find-skills
- **Other** (2): changelog, frontend-design

### Skills with Reference Files

Some skills include `references/` subdirectories with supplementary markdown.
Gemini CLI's skill loader reads these when the skill body references them,
since the skill's directory is allowlisted for file reads upon activation:

- `rails-8/references/` (12 files)
- `rails-conventions/references/` (4 files)
- `mermaid/references/` (18 files)
- `security-analysis/references/` (1 file)
- `jq/references/` (2 files)
- `heroku-cli/references/` (1 file)
- `product-requirements-doc/references/` + `examples/` (2 files)
- `gh-cli/workflows/` (1 file)

### Gemini CLI Skill Activation

Gemini uses **model-driven activation** (not keyword matching):

1. All skill `name` + `description` fields are injected into the system prompt
2. Gemini's model semantically matches user requests to skill descriptions
3. On match, it calls `activate_skill` built-in tool
4. User sees a confirmation prompt, then the skill body is injected

This means **description quality matters more for Gemini** than for Claude
Code. Descriptions should be specific about when to trigger.

### Approach Options

#### Option A: Symlink to `~/.agents/skills/` (Recommended)

Add a second symlink in `dotfiles.yaml`:

```yaml
claude/skills: ~/.agents/skills
```

This places skills at the cross-client interoperability path. Both Claude
Code and Gemini CLI scan `~/.agents/skills/`.

**Trade-off:** Claude Code would find skills at both `~/.claude/skills/` and
`~/.agents/skills/`, potentially loading duplicates. To avoid this, replace
the `~/.claude/skills` symlink with the `~/.agents/skills` one.

#### Option B: Symlink `~/.gemini/skills/` separately

Add to `dotfiles.yaml`:

```yaml
claude/skills: ~/.gemini/skills
```

Keep both the existing `~/.claude/skills` and new `~/.gemini/skills` symlinks
pointing to the same source directory.

**Trade-off:** Two symlinks to maintain, but no risk of duplicate loading.

#### Option C: Use `gemini skills link` command

```bash
gemini skills link ~/.claude/skills --scope user
```

This creates symlinks inside `~/.gemini/skills/` pointing to each skill.

**Trade-off:** Not managed by dotfiles.yaml; breaks the declarative workflow.

### Spec Fields Not Currently Used

The Agent Skills spec supports optional fields your skills don't use:

| Field | Purpose | Recommendation |
| ----- | ------- | -------------- |
| `license` | License identifier | Skip - personal dotfiles |
| `compatibility` | OS/tool requirements | Could add for tool-specific skills |
| `metadata` | Arbitrary key-value | Skip unless needed |
| `allowed-tools` | Pre-approved tool list | Experimental; skip for now |

### Technical Constraints

- **Trust gate:** Gemini CLI only loads workspace-level skills from trusted
  folders. User-level skills (`~/.agents/skills/`) load without trust prompts.
- **Deduplication:** If the same skill name appears at multiple scan paths,
  workspace overrides user overrides extension. No conflict at user level if
  only one path contains each skill name.
- **Allowed-tools field:** Experimental across implementations; Gemini CLI
  may not honor it. Not a concern since your skills don't use it.

## Open Questions

1. **Duplicate loading risk:** Does Claude Code deduplicate skills found at
   both `~/.claude/skills/` and `~/.agents/skills/`? If not, Option A
   requires removing the `~/.claude/skills` symlink.
2. **Reference file access:** Does Gemini CLI's skill directory allowlisting
   extend to subdirectories like `references/`? The spec implies yes, but
   testing would confirm.
3. **Plugin-integrated skills:** Skills like `beads` coordinate with Claude
   Code plugins. These will load in Gemini but the plugin integration won't
   work - is that acceptable?

## Recommendations

1. **Start with Option B** (dual symlinks) as the safest approach:

   ```yaml
   # dotfiles.yaml
   symlinks:
     claude/skills: ~/.claude/skills
     claude/skills: ~/.gemini/skills   # Add this line
   ```

   This requires no changes to existing skills and avoids duplicate-loading
   risk.

2. **Test with a simple skill first** - Verify `bat` or `eza` triggers
   correctly in Gemini CLI before rolling out all 39.

3. **Review descriptions** - Since Gemini uses semantic matching, review
   skill descriptions for clarity. Skills with vague descriptions may not
   trigger reliably.

4. **Long-term: Migrate to `.agents/skills/`** - Once you confirm Claude
   Code deduplicates properly, switch to the single cross-client path and
   remove the tool-specific symlinks.
