# Plan: worktree-refactor (2026-03-14)

## Summary

Refactor the `wt` worktree tooling from bare-clone layouts (`.bare/` + `.git`
pointer file) to normal-clone layouts with `.worktrees/` subdirectories. This
resolves incompatibilities with Claude Code native worktrees and beads hooks,
simplifies the mental model (main branch lives at repo root), and eliminates the
need for the `git-clone-bare-for-worktrees` setup script. The refactor touches
8 files in the dotfiles repo plus documentation updates.

## Stakes Classification

**Level**: Medium

**Rationale**: The change modifies multiple interconnected files (shell script,
zsh plugin, git config, starship prompt, skill docs, CLAUDE.md) and affects
daily workflow tooling. However, the changes are well-understood, existing
projects can be migrated incrementally, and rollback is straightforward (revert
the commits). No external services or APIs are involved.

## Context

**Research**: [`docs/plans/2026-03-14-worktree-refactor-research.md`](./2026-03-14-worktree-refactor-research.md)

**Affected Areas**:

| File | Role | Change Type |
|------|------|-------------|
| `bin/wt` | Main worktree manager CLI | Rewrite core detection and paths |
| `bin/git-clone-bare-for-worktrees` | Bare-clone setup script | Delete |
| `zsh/bostonaholic.plugin.zsh` | Zsh wrapper + completions | Update paths and filters |
| `git/config` | Git aliases | Remove `cb` alias |
| `agents/skills/bare-worktrees/SKILL.md` | Skill documentation | Delete (replaced by new dir) |
| `agents/skills/worktrees/SKILL.md` | Skill documentation | Create (replacement) |
| `starship/starship.toml` | Prompt repo name detection | Simplify bare-clone cases |
| `bin/dev` | Dev session launcher | Update comment |
| `CLAUDE.md` | Project AI instructions | Update worktree guidance |
| `~/.claude/CLAUDE.md` | Global AI instructions | Update worktree section |

## Success Criteria

- [ ] `wt new feature-x` creates worktree at `$repo/.worktrees/feature-x/`
- [ ] `wt add existing-branch` creates worktree at `$repo/.worktrees/existing-branch/`
- [ ] `wt main` returns repo root path (no worktree creation)
- [ ] `wt rm feature-x` removes `$repo/.worktrees/feature-x/` and deletes the branch
- [ ] `wt cd feature-x` outputs path `$repo/.worktrees/feature-x`
- [ ] `wt ls` lists worktrees correctly, filtering out repo root
- [ ] `wt new` auto-creates `.worktrees/` directory on first use
- [ ] `bin/git-clone-bare-for-worktrees` is deleted
- [ ] `git cb` alias is removed from `git/config`
- [ ] Zsh completions work for all subcommands with new paths
- [ ] Zsh wrapper auto-cd works for `main`, `new`, `add`, `cd` subcommands
- [ ] Skill directory is `agents/skills/worktrees/` (not `bare-worktrees/`)
- [ ] `.worktrees/` is in global gitignore (`git/ignore`) -- already present
- [ ] Starship prompt displays repo name correctly for normal clones
- [ ] `shellcheck bin/wt` passes
- [ ] All CLAUDE.md worktree guidance references the new layout

## Implementation Steps

### Phase 1: Rewrite `bin/wt` core script

This is the central change. All other phases depend on the script working
correctly.

#### Step 1.1: Update script header and `find_project_root()`

- **Files**: `bin/wt:1-32`
- **Action**:
  - Update the script header comment: change "bare-clone layouts" to
    "normal git repos", remove reference to `git clone-bare-for-worktrees`,
    update the description to say worktrees live in `.worktrees/`
  - Replace `find_project_root()`: instead of walking up looking for
    `.bare/` + `.git` file, use `git rev-parse --show-toplevel` to find the
    repo root. This is simpler, standard, and works for normal clones
- **Verify**: `source bin/wt && find_project_root` returns the correct repo
  root when run from inside a normal git repo
- **Complexity**: Small

#### Step 1.2: Replace `require_bare_layout()` with `require_git_repo()`

- **Files**: `bin/wt:34-42`
- **Action**:
  - Rename function to `require_git_repo()`
  - Change logic to check for any git repo (use `find_project_root` or
    `git rev-parse --show-toplevel`)
  - Update error message: remove reference to `git clone-bare-for-worktrees`,
    say "Not inside a git repository" instead
- **Verify**: Function exits with error outside a git repo, returns root
  path inside one
- **Complexity**: Small

#### Step 1.3: Update `copy_env_files()` source directory

- **Files**: `bin/wt:44-54`
- **Action**:
  - Change source from `$root/main` to `$root` (repo root is the main
    working tree in normal clones)
  - Update the echo message from "main worktree" to "repo root"
- **Verify**: `.env` files are copied from repo root to new worktree
  directory
- **Complexity**: Small

#### Step 1.4: Simplify `cmd_main()`

- **Files**: `bin/wt:98-112`
- **Action**:
  - Remove worktree creation logic entirely
  - Simply call `require_git_repo` and echo the repo root
  - The main branch already lives at the repo root in normal clones
- **Verify**: `wt main` outputs the repo root path without creating any
  worktree
- **Complexity**: Small

#### Step 1.5: Add `ensure_worktrees_dir()` helper

- **Files**: `bin/wt` (new function, insert after `validate_name`)
- **Action**:
  - Create function `ensure_worktrees_dir()` that takes `$root` as argument
  - Creates `$root/.worktrees/` if it does not exist
  - Prints a message to stderr on first creation: `"wt: created .worktrees/
    directory"`
- **Verify**: Function creates directory on first call, is a no-op on
  subsequent calls
- **Complexity**: Small

#### Step 1.6: Update `cmd_new()` to use `.worktrees/` path

- **Files**: `bin/wt:124-157`
- **Action**:
  - Change `worktree_dir` from `$root/$name` to `$root/.worktrees/$name`
  - Call `ensure_worktrees_dir "$root"` before creating the worktree
  - Update the `git worktree add` command to use the new path
  - Update all references from `require_bare_layout` to `require_git_repo`
- **Verify**: `wt new test-branch` creates worktree at
  `$repo/.worktrees/test-branch`
- **Complexity**: Small

#### Step 1.7: Update `cmd_add()` to use `.worktrees/` path

- **Files**: `bin/wt:159-186`
- **Action**:
  - Change `worktree_dir` from `$root/$name` to `$root/.worktrees/$name`
  - Call `ensure_worktrees_dir "$root"` before creating the worktree
  - Update all references from `require_bare_layout` to `require_git_repo`
- **Verify**: `wt add existing-branch` creates worktree at
  `$repo/.worktrees/existing-branch`
- **Complexity**: Small

#### Step 1.8: Update `cmd_rm()` to use `.worktrees/` path

- **Files**: `bin/wt:188-237`
- **Action**:
  - Change `worktree_dir` from `$root/$name` to `$root/.worktrees/$name`
  - Update `require_bare_layout` call to `require_git_repo`
  - Keep the `main` protection check (prevent removing if name equals the
    main branch, though it would not be a `.worktrees/` entry anyway)
- **Verify**: `wt rm test-branch` removes `$repo/.worktrees/test-branch`
- **Complexity**: Small

#### Step 1.9: Update `cmd_cd()` and `cmd_path()` to use `.worktrees/` path

- **Files**: `bin/wt:239-263`
- **Action**:
  - Change `worktree_dir` from `$root/$name` to `$root/.worktrees/$name`
  - Update `require_bare_layout` call to `require_git_repo`
- **Verify**: `wt cd test-branch` outputs `$repo/.worktrees/test-branch`
- **Complexity**: Small

#### Step 1.10: Update `list_worktree_names()` filtering

- **Files**: `bin/wt:64-76`
- **Action**:
  - Change awk filter: instead of excluding `.bare`, filter to only include
    paths that contain `/.worktrees/` and extract just the name portion
    (everything after `/.worktrees/`)
  - This ensures Claude Code worktrees (in `.claude/worktrees/`) are not
    shown in `wt` listings
- **Verify**: `list_worktree_names` shows only `.worktrees/` entries, not
  the repo root or Claude Code worktrees
- **Complexity**: Small

#### Step 1.11: Update `cmd_list()` and `cmd_prune()` calls

- **Files**: `bin/wt:265-275`
- **Action**:
  - Update `require_bare_layout` calls to `require_git_repo`
- **Verify**: `wt ls` and `wt prune` work in a normal git repo
- **Complexity**: Small

#### Step 1.12: Update `cmd__root()` hidden subcommand

- **Files**: `bin/wt:390-392`
- **Action**:
  - Update to call `require_git_repo` instead of `require_bare_layout`
- **Verify**: `wt _root` outputs the repo root in a normal git repo
- **Complexity**: Small

#### Step 1.13: Update all help text

- **Files**: `bin/wt:277-387`
- **Action**:
  - `cmd_help()`: Change "bare-clone layouts" to "git worktree manager",
    remove "Requires a bare-clone layout" line, update description to say
    worktrees live in `.worktrees/`
  - `cmd_main_help()`: Change "Enter main/ worktree" to "cd to repo root
    (main branch)"
  - `cmd_rm_help()`: Update "cannot be 'main'" note
  - All other help functions: no changes needed
- **Verify**: `wt help` shows no references to bare clones, `.bare/`, or
  `git clone-bare-for-worktrees`
- **Complexity**: Small

#### Step 1.14: Run shellcheck

- **Files**: `bin/wt`
- **Action**: Run `shellcheck bin/wt` and fix any warnings
- **Verify**: `shellcheck bin/wt` exits with code 0
- **Complexity**: Small

### Phase 2: Delete `bin/git-clone-bare-for-worktrees` and remove `cb` alias *(parallel with Phase 3, 4, 5, 6)*

These are independent deletions that do not affect Phase 1's code.

#### Step 2.1: Delete the bare-clone script

- **Files**: `bin/git-clone-bare-for-worktrees`
- **Action**: Delete the file with `git rm bin/git-clone-bare-for-worktrees`
- **Verify**: File no longer exists; `git status` shows it staged for
  deletion
- **Complexity**: Small

#### Step 2.2: Remove `cb` alias from git config

- **Files**: `git/config:62`
- **Action**: Delete the line `cb = clone-bare-for-worktrees`
- **Verify**: `git config --get alias.cb` returns nothing (after symlink
  is refreshed)
- **Complexity**: Small

### Phase 3: Update `zsh/bostonaholic.plugin.zsh` *(parallel with Phase 2, 4, 5, 6)*

#### Step 3.1: Update `wt()` shell wrapper -- `rm` fallback cd

- **Files**: `zsh/bostonaholic.plugin.zsh:68-75`
- **Action**:
  - Change the `rm` case: instead of calling `command wt path main` for
    the fallback directory, use `git rev-parse --show-toplevel` to get the
    repo root
  - Update variable name from `main_path` to `root_path` for clarity
- **Verify**: After `wt rm`, if the current directory was removed, shell
  cd's to repo root
- **Complexity**: Small

#### Step 3.2: Update `_wt()` completion -- worktree name filtering

- **Files**: `zsh/bostonaholic.plugin.zsh:109-143`
- **Action**:
  - Update the awk filter in the `rm` and `cd|path` completion cases:
    instead of filtering out `.bare`, filter to only include paths
    containing `/.worktrees/` and extract the name portion
  - This matches the updated `list_worktree_names()` logic in `bin/wt`
- **Verify**: Tab completion for `wt rm`, `wt cd`, and `wt path` shows
  only worktree names from `.worktrees/`
- **Complexity**: Small

### Phase 4: Update `starship/starship.toml` *(parallel with Phase 2, 3, 5, 6)*

#### Step 4.1: Simplify repo name detection

- **Files**: `starship/starship.toml:23-41`
- **Action**:
  - The `custom.repo_name` module has a shell command with three cases:
    `*/.bare/worktrees/*`, `*.bare`, and a fallback. The bare-clone cases
    will no longer be needed for new repos, but should be kept temporarily
    for migration compatibility (existing bare-clone repos may still exist)
  - Update the description from "handling bare worktree setups" to
    "handling worktree setups"
  - Add a comment noting the `.bare` cases are for legacy compatibility and
    can be removed after all repos are migrated
- **Verify**: Starship prompt shows correct repo name in both normal repos
  and any remaining bare-clone repos
- **Complexity**: Small

### Phase 5: Update `bin/dev` comment *(parallel with Phase 2, 3, 4, 6)*

#### Step 5.1: Update comment in `bin/dev`

- **Files**: `bin/dev:37-39`
- **Action**:
  - Update the comment from "normal repos (.git) and bare repo worktrees
    (.bare)" to "normal repos (.git), repos with .worktrees/, and legacy
    bare repo worktrees (.bare)"
  - The actual code (`git rev-parse --git-common-dir`) works correctly for
    all layouts and does not need changing
- **Verify**: Comment accurately describes the code's behavior
- **Complexity**: Small

### Phase 6: Rename skill directory and rewrite skill document *(parallel with Phase 2, 3, 4, 5)*

#### Step 6.1: Create new skill directory and document

- **Files**: `agents/skills/worktrees/SKILL.md` (new file)
- **Action**:
  - Create directory `agents/skills/worktrees/`
  - Write new `SKILL.md` with:
    - Updated frontmatter: name `worktrees`, description referencing
      normal clones and `.worktrees/` layout
    - New layout diagram showing `.git/` directory + `.worktrees/` container
    - Updated cloning instructions: normal `git clone` (no special script)
    - Updated `wt` CLI command table with new paths
    - Section on coexistence with Claude Code native worktrees
      (`.claude/worktrees/` vs `.worktrees/`)
    - Migration notes for transitioning from bare-clone layout
    - Remove all references to `.bare/`, `git cb`, bare clones as the
      current approach
- **Verify**: `SKILL.md` contains no references to `.bare/` or
  `git clone-bare-for-worktrees` as the current workflow (migration section
  may reference them historically)
- **Complexity**: Medium

#### Step 6.2: Delete old skill directory

- **Files**: `agents/skills/bare-worktrees/SKILL.md`
- **Action**: `git rm -r agents/skills/bare-worktrees/`
- **Verify**: Directory no longer exists
- **Complexity**: Small

### Phase 7: Update documentation

Depends on Phases 1-6 being complete so documentation reflects the final
state.

#### Step 7.1: Update project CLAUDE.md worktree guidance

- **Files**: `CLAUDE.md` (project root)
- **Action**:
  - No worktree-specific sections exist in the project CLAUDE.md currently,
    but the "Landing the Plane" section references `bd sync` which is
    related to worktree workflows. No changes needed here.
  - Verify the directory structure section still accurately reflects the
    repo layout after skill directory rename. The `agents/skills/` line
    is generic and still correct.
- **Verify**: CLAUDE.md is accurate for the new state
- **Complexity**: Small

#### Step 7.2: Update global `~/.claude/CLAUDE.md` worktree guidance

- **Files**: `claude/CLAUDE.md` (symlinked to `~/.claude/CLAUDE.md`)
- **Action**:
  - Update the "Git Worktrees" section (lines 66-73):
    - Change "The `wt` command handles env file copying from the main
      worktree" to "The `wt` command handles env file copying from the
      repo root"
    - The existing guidance about Husky hooks, `.env` files, and tracking
      branch cleanup remains accurate
- **Verify**: `claude/CLAUDE.md` worktree section references repo root
  instead of main worktree
- **Complexity**: Small

### Phase 8: Validation and cleanup

Depends on all previous phases.

#### Step 8.1: Run shellcheck on all modified scripts

- **Files**: `bin/wt`, `bin/dev`
- **Action**: Run `shellcheck bin/wt bin/dev`
- **Verify**: Both pass with no warnings
- **Complexity**: Small

#### Step 8.2: Verify dotfiles.yaml symlinks

- **Files**: `dotfiles.yaml`
- **Action**:
  - Check that the `agents/skills` symlink entries still work. The symlinks
    point to the `agents/skills` directory (not individual skill
    subdirectories), so renaming `bare-worktrees/` to `worktrees/` inside
    that directory requires no `dotfiles.yaml` changes
  - The `bin: ~/bin` symlink covers `bin/wt` and the deletion of
    `bin/git-clone-bare-for-worktrees` -- no changes needed
  - Verify `git/ignore` already contains `.worktrees/` (confirmed: it does)
- **Verify**: `dotfiles.yaml` requires no changes; symlinks are correct
- **Complexity**: Small

#### Step 8.3: End-to-end manual verification

- **Files**: N/A (manual verification)
- **Action**: In a test normal-clone repo, verify the full workflow:
  - `wt` or `wt ls` -- lists worktrees (initially just repo root)
  - `wt main` -- outputs repo root, shell cd's there
  - `wt new test-feature` -- creates `.worktrees/test-feature/`, cd's in
  - `wt cd test-feature` -- cd's into the worktree
  - `wt path test-feature` -- prints the path
  - `wt ls` -- shows `test-feature` in the list
  - `wt rm test-feature` -- removes worktree and branch
  - Tab completion works for `wt cd <tab>`, `wt rm <tab>`
  - `wt new test-2 v1.0.0` -- creates from a specific start point (if tag
    exists)
  - Verify `.env` files are copied from repo root to new worktrees
- **Manual test cases**:
  - [ ] `wt main` outputs repo root
  - [ ] `wt new` creates worktree in `.worktrees/`
  - [ ] `wt add` creates worktree for existing branch in `.worktrees/`
  - [ ] `wt rm` removes worktree from `.worktrees/` and deletes branch
  - [ ] `wt rm --keep-branch` removes worktree but keeps branch
  - [ ] `wt cd` navigates to worktree in `.worktrees/`
  - [ ] `wt ls` lists only `.worktrees/` entries
  - [ ] Tab completion shows correct worktree names
  - [ ] `.env` copying works from repo root
  - [ ] `wt help` shows no bare-clone references
  - [ ] Starship prompt shows correct repo name
  - [ ] `wt` errors gracefully outside a git repo
- **Verify**: All manual test cases pass
- **Complexity**: Medium

## Test Strategy

### Automated Tests

This project uses shell scripts with no test framework. Verification is
manual and via shellcheck.

| Test Case | Type | Input | Expected Output |
|---|---|---|---|
| shellcheck bin/wt | Lint | Modified script | Exit code 0, no warnings |
| shellcheck bin/dev | Lint | Modified script | Exit code 0, no warnings |

### Manual Verification

- [ ] `wt main` in a normal clone outputs repo root path
- [ ] `wt new feature-x` creates `$repo/.worktrees/feature-x/` and cd's in
- [ ] `wt new feature-x` auto-creates `.worktrees/` directory on first use
- [ ] `wt add existing` creates `$repo/.worktrees/existing/` for an existing branch
- [ ] `wt rm feature-x` removes the worktree directory and deletes the branch
- [ ] `wt rm feature-x --keep-branch` removes directory but keeps branch
- [ ] `wt rm main` is blocked with an error
- [ ] `wt cd feature-x` outputs the correct path
- [ ] `wt ls` shows worktrees without repo root or Claude Code worktrees
- [ ] `wt help` contains no references to bare clones
- [ ] Tab completion works for `wt cd`, `wt rm`, `wt add`, `wt new`
- [ ] `wt` outside a git repo shows a clear error message
- [ ] `.env` files are copied from repo root to new worktrees
- [ ] `git cb` is no longer a valid git alias
- [ ] Starship prompt shows correct repo name in normal repos
- [ ] `bin/git-clone-bare-for-worktrees` no longer exists in `~/bin/`

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Existing bare-clone repos stop working with new `wt` | High -- daily workflow breaks | Keep starship `.bare` detection for migration period; migrate repos one at a time; document migration procedure in skill |
| Uncommitted work lost during repo migration | High -- data loss | Migration is manual and per-project; not part of this refactor; document that users must commit/push all work before migrating |
| `list_worktree_names()` awk filter breaks completions | Medium -- tab completion stops working | Test manually after changes; filter logic is straightforward |
| Muscle memory: `git cb` still typed | Low -- minor friction | Command will error with "not found" which is clear enough; no deprecation wrapper needed since only one user |
| Claude Code and `wt` worktrees interfere with each other | Low -- separate directories | `.claude/worktrees/` and `.worktrees/` are distinct paths; `list_worktree_names()` filters to `.worktrees/` only |

## Rollback Strategy

All changes are within the dotfiles repo. Rollback is a simple `git revert` of
the commit(s). Since the refactored `wt` will not work with existing bare-clone
repos (and the old `wt` will not work with normal repos using `.worktrees/`),
rollback is only needed if the refactor is abandoned before any repos are
migrated.

For partial rollback during migration: keep both the old
`git-clone-bare-for-worktrees` script and the new `wt` cannot coexist (they
detect different layouts). The clean approach is to complete the tooling refactor
first, then migrate repos one by one.

## Migration Notes (Out of Scope)

Per-project migration from bare-clone to normal-clone is documented in the
research but is **not part of this implementation plan**. The skill document
(Phase 6) will include migration guidance. Each project migration involves:

1. Push all branches to remote
2. Fresh `git clone` in a new location
3. Move `.env` files to the new repo root
4. Re-create worktrees with `wt new` / `wt add`
5. Remove old bare-clone directory

## Status

- [x] Plan approved
- [x] Implementation started
- [x] Implementation complete
