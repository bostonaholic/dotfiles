# Plan: Dotfiles Unification (2026-01-28)

## Summary

Unify personal dotfiles (this repo) and work dotfiles (`/Users/matthew/code/bostonaholic/shopify-dotfiles`) into a single repository with profile-based configuration. Create three YAML files (`dotfiles.shared.yaml`, `dotfiles.work.yaml`, `dotfiles.personal.yaml`) and corresponding Brewfiles, implement profile detection and YAML merging, and provide v2 installation scripts that auto-detect the environment and install the correct configuration subset.

## Stakes Classification

**Level**: High

**Rationale**:
- Affects critical development environment configuration across two machines
- Hard to rollback if dotfiles break (could lose working setup)
- Wide impact on daily workflow (shell, editors, git, Claude, all dev tools)
- Risk of missing or incorrectly categorizing configs during migration
- Requires careful testing on both environments before cutover

## Context

**Design**: [docs/plans/2026-01-28-unified-dotfiles-design.md](./2026-01-28-unified-dotfiles-design.md)

**Research**: [docs/plans/2026-01-28-dotfiles-unification-research.md](./2026-01-28-dotfiles-unification-research.md)

**Affected Areas**:
- Shell configuration (zsh)
- Homebrew packages (100+ packages)
- Claude Code configuration
- Git, vim, emacs, ghostty, gpg configs
- Installation and update scripts
- All symlinked dotfiles

## Success Criteria

- [ ] Three YAML files created with correct categorization (shared, work, personal)
- [ ] Three Brewfiles created with correct package splits
- [ ] Profile detection script works correctly (prompts on first run, remembers choice)
- [ ] YAML merge script combines configs without conflicts
- [ ] install-v2.sh successfully installs on personal machine
- [ ] install-v2.sh successfully installs on work machine
- [ ] No loss of functionality from current setup on either machine
- [ ] All existing symlinks, packages, and scripts are accounted for
- [ ] Work repo remains untouched (backup preserved)

## Implementation Steps

### Phase 1: Preparation

#### Step 1.1: Add .dotfiles_profile to .gitignore

- **Files**: `.gitignore:1`
- **Action**: Add `.dotfiles_profile` to `.gitignore` to prevent local profile selection from being committed
- **Verify**: `git check-ignore ~/.dotfiles_profile` returns positive match
- **Complexity**: Small

#### Step 1.2: Create profile detection script

- **Files**: `scripts/detect_profile.sh` (new file)
- **Action**: Create bash script that checks for `~/.dotfiles_profile`, prompts if missing, saves choice
- **Verify**: Run script twice - first run prompts, second run returns saved value without prompting
- **Complexity**: Small

#### Step 1.3: Make detect_profile.sh executable

- **Files**: `scripts/detect_profile.sh`
- **Action**: Run `chmod +x scripts/detect_profile.sh`
- **Verify**: `ls -l scripts/detect_profile.sh` shows executable permissions
- **Complexity**: Small

#### Step 1.4: Create YAML merge script

- **Files**: `scripts/merge_yaml.py` (new file)
- **Action**: Create Python script that deep merges two YAML files, errors on conflicts
- **Verify**: Test with sample YAML files - successful merge and conflict detection
- **Complexity**: Medium

#### Step 1.5: Make merge_yaml.py executable

- **Files**: `scripts/merge_yaml.py`
- **Action**: Run `chmod +x scripts/merge_yaml.py`
- **Verify**: `ls -l scripts/merge_yaml.py` shows executable permissions
- **Complexity**: Small

### Phase 2: Verify Shared Configs

**Purpose**: Confirm that configs assumed to be shared are actually identical between repos.

**Findings** (2026-01-28):
| Config | Status | Decision |
|--------|--------|----------|
| git/config | SIGNIFICANT DIFF | Profile-specific - Different emails, signing keys (SSH vs GPG), aliases |
| git/ignore | MODERATE DIFF | Merge to shared - Personal has more entries |
| vim/my_configs.vim | DOESN'T EXIST IN WORK | Personal-only |
| emacs/spacemacs | SIGNIFICANT DIFF | Profile-specific - Different layers, rbenv vs chruby, copilot |
| ghostty/config | MINOR DIFF | Can share - Only font-size differs (16 vs 14) |
| gpg/gpg-agent.conf | MINOR DIFF | Can share - Personal has comments |
| ruby/pryrc | IDENTICAL | Shared |

#### Step 2.1: Diff git configs

- **Files**: `git/config` vs `/Users/matthew/code/bostonaholic/shopify-dotfiles/git/.gitconfig`
- **Action**: Run `diff git/config /Users/matthew/code/bostonaholic/shopify-dotfiles/git/.gitconfig`
- **Verify**: Either identical (can be shared) or document differences (need variants)
- **Complexity**: Small

#### Step 2.2: Diff git ignore files

- **Files**: `git/ignore` vs `/Users/matthew/code/bostonaholic/shopify-dotfiles/git/.gitignore`
- **Action**: Run `diff git/ignore /Users/matthew/code/bostonaholic/shopify-dotfiles/git/.gitignore`
- **Verify**: Either identical (can be shared) or document differences (need variants)
- **Complexity**: Small

#### Step 2.3: Diff vim configs

- **Files**: `vim/my_configs.vim` vs `/Users/matthew/code/bostonaholic/shopify-dotfiles/vim/.my_configs.vim`
- **Action**: Run `diff vim/my_configs.vim /Users/matthew/code/bostonaholic/shopify-dotfiles/vim/.my_configs.vim`
- **Verify**: Either identical (can be shared) or document differences (need variants)
- **Complexity**: Small

#### Step 2.4: Diff emacs configs

- **Files**: `emacs/spacemacs` vs `/Users/matthew/code/bostonaholic/shopify-dotfiles/emacs/.spacemacs`
- **Action**: Run `diff emacs/spacemacs /Users/matthew/code/bostonaholic/shopify-dotfiles/emacs/.spacemacs`
- **Verify**: Either identical (can be shared) or document differences (need variants)
- **Complexity**: Small

#### Step 2.5: Diff ghostty configs

- **Files**: `ghostty/config` vs `/Users/matthew/code/bostonaholic/shopify-dotfiles/ghostty/config`
- **Action**: Run `diff ghostty/config /Users/matthew/code/bostonaholic/shopify-dotfiles/ghostty/config`
- **Verify**: Either identical (can be shared) or document differences (need variants)
- **Complexity**: Small

#### Step 2.6: Diff gpg configs

- **Files**: `gpg/gpg-agent.conf` vs `/Users/matthew/code/bostonaholic/shopify-dotfiles/gpg/gpg-agent.conf`
- **Action**: Run `diff gpg/gpg-agent.conf /Users/matthew/code/bostonaholic/shopify-dotfiles/gpg/gpg-agent.conf`
- **Verify**: Either identical (can be shared) or document differences (need variants)
- **Complexity**: Small

#### Step 2.7: Diff ruby pryrc

- **Files**: `ruby/pryrc` vs `/Users/matthew/code/bostonaholic/shopify-dotfiles/ruby/.pryrc`
- **Action**: Run `diff ruby/pryrc /Users/matthew/code/bostonaholic/shopify-dotfiles/ruby/.pryrc`
- **Verify**: Either identical (can be shared) or document differences (need variants)
- **Complexity**: Small

### Phase 3: Create Brewfiles

#### Step 3.1: Create Brewfile.shared

- **Files**: `Brewfile.shared` (new file)
- **Action**: Extract ~30 shared packages from research document into new Brewfile with proper structure (taps, brews, casks)
- **Verify**: Run `brew bundle --file=Brewfile.shared --dry-run` - no errors, shows correct packages
- **Complexity**: Medium

#### Step 3.2: Create Brewfile.work

- **Files**: `Brewfile.work` (new file)
- **Action**: Create work-specific Brewfile with lumen, watchman, python, node
- **Verify**: Run `brew bundle --file=Brewfile.work --dry-run` - no errors
- **Complexity**: Small

#### Step 3.3: Create Brewfile.personal

- **Files**: `Brewfile.personal` (new file)
- **Action**: Extract ~100+ personal-only packages from research document into new Brewfile
- **Verify**: Run `brew bundle --file=Brewfile.personal --dry-run` - no errors, shows correct packages
- **Complexity**: Large

### Phase 4: Create YAML Configuration Files

#### Step 4.1: Create dotfiles.shared.yaml

- **Files**: `dotfiles.shared.yaml` (new file)
- **Action**: Create shared YAML with:
  - Shared directories (~/bin, ~/.claude, ~/.config/git, etc.)
  - Shared symlinks (~11 items from research)
  - Shared scripts post_install (oh-my-zsh, Spacemacs, vimrc)
  - Reference to Brewfile.shared for packages
- **Verify**: YAML syntax valid, all shared items from research included
- **Complexity**: Medium

#### Step 4.2: Prepare work-specific zshrc

- **Files**: `zsh/zshrc.work` (new file)
- **Action**: Copy work zshrc from `/Users/matthew/code/bostonaholic/shopify-dotfiles/zsh/.zshrc` to `zsh/zshrc.work`
- **Verify**: File exists, content matches work repo
- **Complexity**: Small

#### Step 4.3: Prepare work-specific Claude settings

- **Files**: `claude/settings.work.json` (new file)
- **Action**: Copy work Claude settings from `/Users/matthew/code/bostonaholic/shopify-dotfiles/claude/settings.json` to `claude/settings.work.json`
- **Verify**: File exists, content matches work repo (has apiKeyHelper, Shopify proxy)
- **Complexity**: Small

#### Step 4.4: Copy work Claude settings.local.json

- **Files**: `claude/settings.local.work.json` (new file)
- **Action**: Copy `/Users/matthew/code/bostonaholic/shopify-dotfiles/claude/settings.local.json` to `claude/settings.local.work.json`
- **Verify**: File exists, content matches work repo
- **Complexity**: Small

#### Step 4.5: Copy work statusline script

- **Files**: `claude/statusline.work.sh` (new file)
- **Action**: Copy `/Users/matthew/code/bostonaholic/shopify-dotfiles/claude/statusline.sh` to `claude/statusline.work.sh`
- **Verify**: File exists, content matches work repo
- **Complexity**: Small

#### Step 4.6: Copy work reflect.ts script

- **Files**: `bin/reflect.ts` (new file)
- **Action**: Copy `/Users/matthew/code/bostonaholic/shopify-dotfiles/bin/reflect.ts` to `bin/reflect.ts`
- **Verify**: File exists, content matches work repo
- **Complexity**: Small

#### Step 4.7: Create dotfiles.work.yaml

- **Files**: `dotfiles.work.yaml` (new file)
- **Action**: Create work YAML with:
  - Work symlinks (zshrc.work → .zshrc, Claude work settings, statusline.work.sh, reflect.ts)
  - Work post_install scripts (Emacs link, Claude Code install, Claude plugins, Xcode setup)
  - Reference to Brewfile.work for packages
- **Verify**: YAML syntax valid, all work items from research included
- **Complexity**: Small

#### Step 4.8: Rename personal zshrc for clarity

- **Files**: `zsh/zshrc` → `zsh/zshrc.personal`
- **Action**: Rename current personal zshrc to make it explicit
- **Verify**: File renamed, git shows rename
- **Complexity**: Small

#### Step 4.9: Rename personal Claude settings for clarity

- **Files**: `claude/settings.json` → `claude/settings.personal.json`
- **Action**: Rename current personal Claude settings to make it explicit
- **Verify**: File renamed, git shows rename
- **Complexity**: Small

#### Step 4.10: Rename personal statusline for clarity

- **Files**: `claude/statusline.clj` → `claude/statusline.personal.clj`
- **Action**: Rename current personal statusline to make it explicit
- **Verify**: File renamed, git shows rename
- **Complexity**: Small

#### Step 4.11: Create dotfiles.personal.yaml

- **Files**: `dotfiles.personal.yaml` (new file)
- **Action**: Create personal YAML with:
  - Personal directories (~/.cursor, ~/.lein, ~/.rbenv, etc.)
  - Personal symlinks (~30 items from research including zshrc.personal, zprofile, Claude personal settings, cursor, vscode, etc.)
  - Personal scripts (35 bin scripts)
  - NPM global packages
  - UV tool packages
  - Personal post_install scripts (rbenv, nodenv, pre-commit, Powerline, macOS settings)
  - Reference to Brewfile.personal for packages
- **Verify**: YAML syntax valid, all personal items from research included
- **Complexity**: Large

### Phase 5: Create V2 Installation Scripts

#### Step 5.1: Create install-v2.sh

- **Files**: `install-v2.sh` (new file)
- **Action**: Create new installer that:
  1. Calls detect_profile.sh to get profile
  2. Calls merge_yaml.py to merge shared + profile YAML
  3. Calls existing install.sh with merged config
  4. Runs brew bundle twice (shared + profile)
  5. Cleans up temp merged YAML
- **Verify**: Script syntax valid, all steps present, has proper error handling
- **Complexity**: Medium

#### Step 5.2: Make install-v2.sh executable

- **Files**: `install-v2.sh`
- **Action**: Run `chmod +x install-v2.sh`
- **Verify**: `ls -l install-v2.sh` shows executable permissions
- **Complexity**: Small

#### Step 5.3: Update install.sh to accept --config flag

- **Files**: `install.sh`
- **Action**: Modify install.sh to optionally read from --config path instead of hardcoded dotfiles.yaml
- **Verify**: `./install.sh --help` shows --config option, script runs with custom config
- **Complexity**: Medium

#### Step 5.4: Create update-v2.sh

- **Files**: `update-v2.sh` (new file)
- **Action**: Create new updater similar to install-v2.sh but for updates
- **Verify**: Script syntax valid, mirrors install-v2.sh logic
- **Complexity**: Small

#### Step 5.5: Make update-v2.sh executable

- **Files**: `update-v2.sh`
- **Action**: Run `chmod +x update-v2.sh`
- **Verify**: `ls -l update-v2.sh` shows executable permissions
- **Complexity**: Small

### Phase 6: Test on Personal Machine

#### Step 6.1: Backup current ~/.dotfiles_profile if exists

- **Files**: `~/.dotfiles_profile`
- **Action**: If file exists, back it up to `~/.dotfiles_profile.backup`
- **Verify**: Backup created or confirmed not needed
- **Complexity**: Small

#### Step 6.2: Test profile detection

- **Files**: `scripts/detect_profile.sh`
- **Action**: Run `./scripts/detect_profile.sh` and select "personal"
- **Verify**: Script prompts for selection, saves to `~/.dotfiles_profile`, returns "personal"
- **Complexity**: Small

#### Step 6.3: Test YAML merge for personal profile

- **Files**: `scripts/merge_yaml.py`
- **Action**: Run `./scripts/merge_yaml.py dotfiles.shared.yaml dotfiles.personal.yaml /tmp/test-merge.yaml`
- **Verify**: No errors, /tmp/test-merge.yaml contains merged config, no conflicts reported
- **Complexity**: Small

#### Step 6.4: Dry-run install-v2.sh on personal

- **Files**: `install-v2.sh`
- **Action**: Run `./install-v2.sh --dry-run`
- **Verify**: Shows what would be installed, no errors, correct profile detected, Brewfiles would be processed
- **Complexity**: Small

#### Step 6.5: Run install-v2.sh on personal machine

- **Files**: `install-v2.sh`
- **Action**: Run `./install-v2.sh -fy` (force yes, overwrites existing)
- **Verify**: Installation completes successfully, no errors, symlinks created, Homebrew packages installed
- **Complexity**: Medium

#### Step 6.6: Verify personal environment after install

- **Files**: Multiple
- **Action**: Check:
  - Shell loads correctly (`exec zsh`)
  - Git config works (`git config --list`)
  - Vim config works (`vim` and `:version`)
  - Claude config works (`claude --version`)
  - All expected symlinks exist
- **Verify**: All checks pass, no broken configs
- **Complexity**: Medium

#### Step 6.7: Test profile detection remembers choice

- **Files**: `scripts/detect_profile.sh`
- **Action**: Run `./scripts/detect_profile.sh` again
- **Verify**: Returns "personal" immediately without prompting
- **Complexity**: Small

### Phase 7: Test on Work Machine

**Note**: These steps will be performed on work machine `/Users/matthew/code/bostonaholic/shopify-dotfiles`

#### Step 7.1: Pull unified dotfiles on work machine

- **Files**: Git repository
- **Action**: On work machine, navigate to dotfiles repo and pull latest changes
- **Verify**: All new files present (YAML files, Brewfiles, v2 scripts)
- **Complexity**: Small

#### Step 7.2: Backup current work ~/.dotfiles_profile if exists

- **Files**: `~/.dotfiles_profile` (on work machine)
- **Action**: If file exists, back it up to `~/.dotfiles_profile.backup`
- **Verify**: Backup created or confirmed not needed
- **Complexity**: Small

#### Step 7.3: Test profile detection on work machine

- **Files**: `scripts/detect_profile.sh`
- **Action**: Run `./scripts/detect_profile.sh` and select "work"
- **Verify**: Script prompts for selection, saves to `~/.dotfiles_profile`, returns "work"
- **Complexity**: Small

#### Step 7.4: Test YAML merge for work profile

- **Files**: `scripts/merge_yaml.py`
- **Action**: Run `./scripts/merge_yaml.py dotfiles.shared.yaml dotfiles.work.yaml /tmp/test-merge.yaml`
- **Verify**: No errors, /tmp/test-merge.yaml contains merged config, no conflicts reported
- **Complexity**: Small

#### Step 7.5: Dry-run install-v2.sh on work machine

- **Files**: `install-v2.sh`
- **Action**: Run `./install-v2.sh --dry-run`
- **Verify**: Shows what would be installed, no errors, correct profile detected (work), Brewfiles would be processed
- **Complexity**: Small

#### Step 7.6: Run install-v2.sh on work machine

- **Files**: `install-v2.sh`
- **Action**: Run `./install-v2.sh -fy` (force yes, overwrites existing)
- **Verify**: Installation completes successfully, no errors, symlinks created, Homebrew packages installed
- **Complexity**: Medium

#### Step 7.7: Verify work environment after install

- **Files**: Multiple
- **Action**: Check:
  - Shell loads correctly with Shopify tools (`exec zsh`, `which spin`, `which dev`)
  - Git config works (`git config --list`)
  - Vim config works (`vim` and `:version`)
  - Claude config works with Shopify proxy (`claude --version`)
  - All expected symlinks exist
  - Work-specific aliases work (`claude`, `cc`)
- **Verify**: All checks pass, no broken configs, Shopify integrations work
- **Complexity**: Medium

#### Step 7.8: Test work-specific functionality

- **Files**: Multiple
- **Action**: Verify:
  - `devx claude` command works
  - Claude uses Shopify API proxy
  - Kubernetes config includes cloudplatform
  - chruby works
  - tec integration loads
- **Verify**: All work-specific features function correctly
- **Complexity**: Small

### Phase 8: Cutover and Cleanup

#### Step 8.1: Rename install.sh to install.v1.sh

- **Files**: `install.sh` → `install.v1.sh`
- **Action**: Rename for backup
- **Verify**: File renamed, git shows rename
- **Complexity**: Small

#### Step 8.2: Rename install-v2.sh to install.sh

- **Files**: `install-v2.sh` → `install.sh`
- **Action**: Make v2 the default installer
- **Verify**: File renamed, git shows rename
- **Complexity**: Small

#### Step 8.3: Rename update.sh to update.v1.sh

- **Files**: `update.sh` → `update.v1.sh`
- **Action**: Rename for backup
- **Verify**: File renamed, git shows rename
- **Complexity**: Small

#### Step 8.4: Rename update-v2.sh to update.sh

- **Files**: `update-v2.sh` → `update.sh`
- **Action**: Make v2 the default updater
- **Verify**: File renamed, git shows rename
- **Complexity**: Small

#### Step 8.5: Update CLAUDE.md with new structure

- **Files**: `CLAUDE.md`
- **Action**: Document:
  - Three YAML files and their purposes
  - Profile detection mechanism
  - How to add new configs (choose shared/work/personal)
  - New installation workflow
- **Verify**: Documentation clear and complete
- **Complexity**: Small

#### Step 8.6: Archive work dotfiles repo

- **Files**: `/Users/matthew/code/bostonaholic/shopify-dotfiles/`
- **Action**: Create archive: `tar -czf ~/shopify-dotfiles-backup-$(date +%Y%m%d).tar.gz /Users/matthew/code/bostonaholic/shopify-dotfiles`
- **Verify**: Archive created, contains all files
- **Complexity**: Small

#### Step 8.7: Add README to archived work repo

- **Files**: `/Users/matthew/code/bostonaholic/shopify-dotfiles/ARCHIVED.md`
- **Action**: Create note explaining repo is archived, configs moved to unified dotfiles
- **Verify**: File created with clear explanation
- **Complexity**: Small

#### Step 8.8: Commit unified dotfiles structure

- **Files**: All new and modified files
- **Action**: Git commit all changes with message: "feat(dotfiles): unify personal and work configs with profile-based system"
- **Verify**: All changes committed, git status clean
- **Complexity**: Small

#### Step 8.9: Push unified dotfiles to remote

- **Files**: Git repository
- **Action**: `git push origin main`
- **Verify**: Changes pushed successfully, remote up to date
- **Complexity**: Small

#### Step 8.10: Test fresh install from scratch (optional confidence check)

- **Files**: All
- **Action**: On a test directory or VM, clone repo and run `./install.sh` from scratch
- **Verify**: Profile selection works, installation succeeds, environment functional
- **Complexity**: Medium

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking current working environment | High - could lose productivity | Keep v1 scripts as backup, test thoroughly before cutover, maintain work repo archive |
| YAML merge conflicts during implementation | Medium - blocks progress | Carefully categorize configs in Phase 2 diffs, ensure no overlaps between shared and profile files |
| Missing configs during migration | Medium - incomplete setup | Use research document as checklist, verify all 153 items from current dotfiles.yaml are accounted for |
| Profile detection fails or corrupts | Low - can manually fix | Test thoroughly in Phase 6/7, keep .dotfiles_profile simple (one word), add error handling |
| install.sh modification breaks existing usage | Medium - affects current workflow | Test --config flag thoroughly, ensure backward compatibility (defaults to dotfiles.yaml if no flag) |
| Work-specific Shopify integrations break | High - blocks work | Extensive testing in Phase 7 step 7.7-7.8, verify all Shopify-specific features before declaring success |
| Brewfile package conflicts between shared/work/personal | Low - easily fixed | Use research document categorization, brew bundle is idempotent so running twice is safe |
| Git merge/rebase issues with ongoing changes | Medium - merge conflicts | Complete implementation quickly, communicate with self about timing, use feature branch if needed |

## Rollback Strategy

If critical issues discovered after cutover:

1. **Immediate rollback**:
   - Rename `install.sh` → `install.v2.sh`
   - Rename `install.v1.sh` → `install.sh`
   - Rename `update.sh` → `update.v2.sh`
   - Rename `update.v1.sh` → `update.sh`
   - Use old dotfiles.yaml and Brewfile

2. **Work machine specific**:
   - Revert to `/Users/matthew/code/bostonaholic/shopify-dotfiles`
   - Run original install.zsh
   - Restore from archive if needed

3. **Partial rollback**:
   - Keep unified structure but fix specific broken config
   - Use git to revert specific file changes
   - Manually fix ~/.dotfiles_profile if needed

4. **Nuclear option**:
   - Git revert entire unification commit
   - Restore work repo from archive
   - Continue using separate repos until issues resolved

## Status

- [x] Plan approved
- [x] Implementation started
- [x] Phase 1 complete (Preparation) - Note: Used bash/yq instead of Python for merge script
- [x] Phase 2 complete (Verify Shared Configs) - Key finding: git/config and emacs/spacemacs need profile variants
- [x] Phase 3 complete (Create Brewfiles)
- [x] Phase 4 complete (Create YAML Configuration Files) - Also added git/config and emacs/spacemacs variants; restructured to shared/work/personal directories
- [x] Phase 5 complete (Create V2 Installation Scripts)
- [x] Phase 6 complete (Test on Personal Machine) - Fixed CONFIG_FILE export bug and --no-lock flag; all 71 symlinks created
- [ ] Phase 7 complete (Test on Work Machine) - Deferred for manual testing
- [x] Phase 8 complete (Cutover and Cleanup) - Scripts renamed, docs updated, committed
- [ ] Implementation complete
