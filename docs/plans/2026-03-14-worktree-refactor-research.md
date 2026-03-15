# Worktree Refactor Research

Consolidation of research into migrating the `wt` worktree tooling from
bare-clone layouts to normal-clone layouts with `.worktrees/` directories,
enabling compatibility with Claude Code native worktrees and beads.

## Executive Summary

The current `wt` system uses bare-clone repos (`.bare/` + `.git` pointer file)
with worktrees as sibling directories. This layout is incompatible with both
Claude Code's native worktree support and the beads hook system. Switching to
normal clones with worktrees under `.worktrees/` resolves both issues, aligns
with standard git conventions, and simplifies the mental model (main branch
lives at repo root, not in a `main/` subdirectory).

The refactor touches 5 files in the dotfiles repo and requires a per-project
migration for any existing bare-clone repos.

## Current State

### Files Involved

| File | Lines | Role |
|------|-------|------|
| `bin/wt` | 435 | Main worktree manager CLI |
| `bin/git-clone-bare-for-worktrees` | 41 | Bare-clone setup script |
| `zsh/bostonaholic.plugin.zsh` (49-176) | 128 | Zsh wrapper + completions |
| `git/config` (line 62) | 1 | `cb` alias for clone script |
| `agents/skills/bare-worktrees/SKILL.md` | 162 | Skill documentation |

### Current Layout (Bare-Clone)

```text
~/code/my-project/
  .bare/              # bare repository (all objects, refs, config)
  .git                # file (not directory) pointing to .bare
  main/               # persistent trunk worktree
  feature-x/          # temporary worktree (sibling directory)
  bugfix-y/           # another temporary worktree
```

### Key Behaviors

- `find_project_root()` walks up looking for `.bare/` + `.git` file
- `require_bare_layout()` enforces bare layout, exits if not found
- `copy_env_files()` copies `.env` files from `main/` to new worktrees
- `cmd_main()` creates/enters the `main/` worktree
- `cmd_rm()` blocks removal of `main` worktree
- `cmd_new()` creates worktrees at `$root/$name` (sibling directories)
- `list_worktree_names()` filters out `.bare/` from porcelain output
- `cmd__root()` hidden subcommand used by zsh completions
- Zsh wrapper intercepts `main`, `new`, `add`, `cd` for auto-cd
- Zsh completions filter worktree names excluding bare repo path

### Problems with Bare Clones

**Claude Code incompatibility:**

- Claude Code creates worktrees at `.claude/worktrees/<name>/` using standard
  `git worktree` with normal (non-bare) repos
- Claude Code expects `.git/` to be a directory (normal clone), not a file
- Branch naming convention: `worktree-<name>`
- Claude Code's `EnterWorktree`/`ExitWorktree` tools, WorktreeCreate/
  WorktreeRemove hooks, and `isolation: "worktree"` subagent config all
  assume normal clone layout

**Beads incompatibility:**

- Beads installs hooks to `.git/hooks/` -- bare clones don't expose this
  properly since `.git` is a file pointing to `.bare/`
- Dolt server state doesn't persist across bare-clone worktrees
- `.beads/` directory location is ambiguous in bare-clone layout
- Database discovery fails at bare repo level

## Target State

### Target Layout (Normal Clone + `.worktrees/`)

```text
~/code/my-project/
  .git/               # normal git directory
  .worktrees/         # worktree container (gitignored)
    feature-x/        # worktree checkout
    bugfix-y/         # another worktree
  .gitignore          # includes .worktrees/
  src/                # main branch working tree at repo root
  ...
```

### Key Properties

- Normal `git clone` -- no special setup script needed
- Main branch lives at repo root (no separate `main/` directory)
- Additional worktrees go in `.worktrees/<name>/`
- `.worktrees/` added to `.gitignore` (per-project)
- Compatible with Claude Code native worktrees (`.claude/worktrees/`)
- Compatible with beads (`.git/hooks/` works normally)
- Claude Code and `wt` can coexist -- they use different subdirectories

## Key Changes

### 1. `bin/wt` -- Rewrite Core Detection and Paths

**`find_project_root()`** -- Replace bare-clone detection.
Current: walks up looking for `.bare/` + `.git` file.
Target: walks up looking for `.git/` directory (standard git root detection),
or delegate to `git rev-parse --show-toplevel`.

**`require_bare_layout()`** -- Rename and relax.
Rename to `require_git_repo()` or similar.
Check for `.git/` directory (normal repo) instead of `.bare/` + `.git` file.
Update error message (no longer directs to `git clone-bare-for-worktrees`).

**`copy_env_files()`** -- Change source directory.
Current: copies from `$root/main/`.
Target: copies from `$root/` (repo root is the main working tree).

**`cmd_main()`** -- Simplify.
Current: creates `main/` worktree if missing, returns its path.
Target: return repo root directly (main branch is already there).
No worktree creation needed -- `cd` to repo root.

**`cmd_new()` / `cmd_add()`** -- Change worktree location.
Current: `$root/$name` (sibling directory).
Target: `$root/.worktrees/$name`.
Ensure `.worktrees/` directory exists (create on first use).
Ensure `.worktrees/` is in `.gitignore` (warn or auto-add if missing).

**`cmd_rm()`** -- Update path and protection.
Current: blocks removal of `main`, operates on `$root/$name`.
Target: operates on `$root/.worktrees/$name`.
After removal, cd fallback goes to `$root` instead of `$root/main`.
Still block removal if name matches the main branch (but it won't be a
worktree directory, so this may become a no-op).

**`cmd_cd()` / `cmd_path()`** -- Update path resolution.
Current: `$root/$name`.
Target: `$root/.worktrees/$name`.

**`list_worktree_names()`** -- Simplify filtering.
Current: filters out `.bare/` from porcelain output.
Target: filter out repo root (main worktree), show only `.worktrees/` entries.
Extract just the name portion from `.worktrees/<name>` paths.

**`cmd_list()`** -- No change needed (delegates to `git worktree list`)

**Help text** -- Update all references from "bare-clone layout" to
".worktrees layout"

### 2. `bin/git-clone-bare-for-worktrees` -- Remove or Replace

Two options:

- **Remove entirely**: normal `git clone` is sufficient; no special script
  needed. Remove the `cb` alias from `git/config`.
- **Replace with `git-clone-for-worktrees`**: a convenience wrapper that does
  `git clone`, creates `.worktrees/`, and adds `.worktrees/` to `.gitignore`.
  Simpler but still provides a smooth onboarding path.

Recommendation: remove the script. The `wt new` / `wt add` commands can
auto-create `.worktrees/` and handle `.gitignore` on demand.

### 3. `git/config` -- Remove `cb` Alias

```gitconfig
[alias]
    cb = clone-bare-for-worktrees   # DELETE this line
```

### 4. `zsh/bostonaholic.plugin.zsh` -- Update Completions

- Completion function `_wt`: update awk filters to handle `.worktrees/`
  prefix instead of filtering `.bare/`
- Wrapper function: update `rm` fallback cd from `$main_path` to repo root
- Remove `main` from subcommands list if `wt main` just cd's to repo root
  (or keep it for convenience -- it's a no-op cd that's still useful for
  "get me back to the main branch")

### 5. `agents/skills/bare-worktrees/SKILL.md` -- Rewrite

- Rename skill directory: `agents/skills/bare-worktrees/` to
  `agents/skills/worktrees/` (or keep the directory and update content)
- Update all layout diagrams, commands, and detection logic
- Remove references to `.bare/`, `git cb`, bare-clone
- Add section on coexistence with Claude Code native worktrees
- Update the comparison table (old vs new is now reversed)

### Summary of Function Changes

| Function | Current Behavior | Target Behavior |
|----------|-----------------|-----------------|
| `find_project_root()` | Look for `.bare/` + `.git` file | `git rev-parse --show-toplevel` |
| `require_bare_layout()` | Enforce bare layout | Enforce any git repo |
| `copy_env_files()` | Copy from `main/` | Copy from repo root |
| `cmd_main()` | Create/enter `main/` worktree | Return repo root |
| `cmd_new()` | Create at `$root/$name` | Create at `$root/.worktrees/$name` |
| `cmd_add()` | Create at `$root/$name` | Create at `$root/.worktrees/$name` |
| `cmd_rm()` | Remove `$root/$name` | Remove `$root/.worktrees/$name` |
| `cmd_cd()` | cd to `$root/$name` | cd to `$root/.worktrees/$name` |
| `list_worktree_names()` | Filter out `.bare/` | Filter to `.worktrees/` entries |

## Risks and Migration Considerations

### Migration of Existing Projects

Every project currently using bare-clone layout needs manual migration:

1. From within a bare-clone project, note all worktree branches with
   uncommitted work
2. Push all branches to remote
3. Remove all worktrees: `git worktree remove <path>` for each
4. Clone fresh with normal `git clone` in a new location
5. Move `.env` files from old `main/` to new repo root
6. Re-create needed worktrees with updated `wt new` / `wt add`
7. Remove old bare-clone directory

A migration script (`scripts/migrate-bare-to-normal`) could automate this,
but given the risk of data loss with uncommitted work, a documented manual
procedure may be safer.

### Risk: Losing Uncommitted Work

Bare-clone worktrees may contain uncommitted changes, stashes, or local
branches not pushed to remote. The migration procedure must account for this.
Mitigation: the migration script/docs should check for dirty worktrees and
refuse to proceed until everything is committed or stashed.

### Risk: Muscle Memory and Habits

Users (and AI agents with the old skill) are trained on `git cb` and the
sibling-directory layout. Mitigation: update the skill document immediately;
the old `git cb` command should print a deprecation warning pointing to the
new workflow if kept temporarily.

### Risk: Claude Code Worktree Coexistence

Claude Code puts its worktrees in `.claude/worktrees/<name>/` with branch
names like `worktree-<name>`. The `wt` tool puts worktrees in
`.worktrees/<name>/`. These are separate directories and should not conflict.
However, `git worktree list` will show both. The `list_worktree_names()`
function should filter to only show `.worktrees/` entries, not Claude Code's
worktrees (and vice versa).

### Risk: `.gitignore` Management

The `.worktrees/` directory must be in `.gitignore` to avoid accidentally
committing worktree contents. Options:

- Auto-add to `.gitignore` on first `wt new` / `wt add` (intrusive)
- Warn if missing and let user add it (safe but noisy)
- Add to global gitignore (`~/.config/git/ignore`) to cover all repos

Recommendation: add `.worktrees/` to the global gitignore
(`~/.config/git/ignore`) so it works everywhere without per-repo changes. This
is already in the dotfiles repo's jurisdiction.

### Risk: `wt sync` Not Yet Implemented

The current `wt` has no `sync` subcommand. The CLAUDE.md references
`bd sync` in the landing-the-plane workflow. If `wt` is the primary worktree
tool, consider whether a `wt sync` command is needed (pull + rebase from
main into worktree branches). This is out of scope for the refactor but worth
noting.

## Open Questions

1. **Keep `wt main` or remove it?** In the new layout, `wt main` would just
   cd to the repo root. This is trivially `cd $(git rev-parse --show-toplevel)`
   but `wt main` is ergonomic and established in muscle memory. Leaning toward
   keeping it.

2. **Global gitignore vs per-repo?** Adding `.worktrees/` to
   `~/.config/git/ignore` covers all repos automatically. Per-repo `.gitignore`
   is more explicit but requires modification of every project. Recommendation:
   global gitignore.

3. **Migration script or manual docs?** A script reduces human error but adds
   maintenance burden. The number of existing bare-clone projects determines
   whether automation is worthwhile. Could start with docs and add a script if
   needed.

4. **Rename the skill directory?** `agents/skills/bare-worktrees/` should
   become `agents/skills/worktrees/` since bare clones are no longer involved.
   This requires updating any symlinks in `dotfiles.yaml` if applicable.

5. **Branch naming convention for `wt new`?** Currently the branch name equals
   the worktree directory name. Claude Code uses `worktree-<name>`. Should `wt`
   adopt the same prefix for consistency, or keep the current direct naming?
   Recommendation: keep direct naming -- the prefix adds noise and `wt` users
   choose their own branch names.

6. **Should `wt` auto-create `.worktrees/` and handle `.gitignore`?** On first
   use in a repo, `wt new` or `wt add` could create `.worktrees/` and add it
   to `.gitignore` if missing. This is convenient but modifies the repo's
   tracked files. With global gitignore, only the directory creation is needed.

7. **What about the `_root` hidden subcommand?** Currently used by zsh
   completions to find the bare-clone root. In the new layout, this becomes
   `git rev-parse --show-toplevel`. The completions could call git directly
   instead of routing through `wt _root`.
