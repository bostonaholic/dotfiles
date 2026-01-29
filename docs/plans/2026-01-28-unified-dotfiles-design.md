# Design: Unified Personal and Work Dotfiles (2026-01-28)

## Problem Statement

Currently managing two separate dotfiles repositories:
- Personal: `/Users/matthew/dotfiles` (this repo)
- Work: `/Users/matthew/code/bostonaholic/shopify-dotfiles`

Shared configurations (zsh, git, vim, etc.) require manual syncing between repos, leading to drift and duplicate maintenance. Work requires specific tooling that conflicts with personal setups, while many core configs should be identical across both environments.

**Key Pain Points:**
- Duplicate maintenance of shared configs
- Manual syncing prone to errors and drift
- Unclear which configs belong in which repo
- Complex setup requiring multiple repo clones

## Chosen Approach

**Separate YAML Files with Merging**

Consolidate into a single repository with three YAML files:
- `dotfiles.shared.yaml` - Configurations for both environments
- `dotfiles.work.yaml` - Work-specific additions (Shopify tooling, etc.)
- `dotfiles.personal.yaml` - Personal-specific additions

The `install.sh` script will:
1. Check for `~/.dotfiles_profile` (not tracked)
2. If missing, prompt user to select profile (work/personal)
3. Save selection to `~/.dotfiles_profile`
4. Load shared YAML + appropriate profile YAML
5. Merge configurations
6. Install the merged set

**Why This Approach:**
- Clear organizational boundaries (shared vs specific)
- Single source of truth eliminates manual syncing
- Explicit about what goes where
- Automatic profile detection with one-time setup

## Design Details

### File Structure

```text
dotfiles/
├── dotfiles.shared.yaml      # Shared configs (gh, zsh base, git, vim)
├── dotfiles.work.yaml         # Work-specific (spin, shopify tools)
├── dotfiles.personal.yaml     # Personal-specific configs
├── .gitignore                 # Add .dotfiles_profile to ignore
├── install.sh                 # Current installer (unchanged)
├── install-v2.sh              # New installer with profile detection & merging
├── update.sh                  # Current updater (unchanged)
├── update-v2.sh               # New updater with profile detection & merging
├── Brewfile                   # Current Brewfile (unchanged during transition)
├── Brewfile.shared            # Shared Homebrew packages
├── Brewfile.work              # Work Homebrew packages
├── Brewfile.personal          # Personal Homebrew packages
├── scripts/
│   ├── detect_profile.sh      # Detect or prompt for profile
│   └── merge_yaml.py          # Merge YAML files
└── [existing directories]

# Not tracked (local only):
~/.dotfiles_profile            # Contains: "work" or "personal"
```

### YAML Structure

Same format as current `dotfiles.yaml`, just split across files:

```yaml
# dotfiles.shared.yaml
symlinks:
  - src: zsh/zshrc
    dest: ~/.zshrc
  - src: git/config
    dest: ~/.gitconfig

packages:
  homebrew: [gh, vim, tmux]
  npm:
    global_packages: [typescript, prettier]
  claude:
    plugins: [beads, rpikit]
```

```yaml
# dotfiles.work.yaml
symlinks:
  - src: zsh/shopify.zsh
    dest: ~/.shopify.zsh

packages:
  homebrew: [spin]
  claude:
    plugins: [plugin-dev]
```

```yaml
# dotfiles.personal.yaml
symlinks:
  - src: zsh/personal-aliases.zsh
    dest: ~/.personal-aliases.zsh

packages:
  homebrew: [personal-tool]
```

### Profile Detection (`scripts/detect_profile.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail

PROFILE_FILE="$HOME/.dotfiles_profile"

if [[ -f "$PROFILE_FILE" ]]; then
  PROFILE=$(cat "$PROFILE_FILE")
  echo "$PROFILE"
else
  echo "Is this a work or personal machine?" >&2
  select profile in "work" "personal"; do
    case $profile in
      work|personal)
        echo "$profile" > "$PROFILE_FILE"
        echo "$profile"
        break
        ;;
      *)
        echo "Please select 1 (work) or 2 (personal)" >&2
        ;;
    esac
  done
fi
```

### Merge Logic (`scripts/merge_yaml.py`)

```python
#!/usr/bin/env python3
"""Merge shared and profile-specific YAML files."""

import sys
import yaml
from pathlib import Path

def deep_merge(base, overlay):
    """Deep merge overlay into base, with overlay taking precedence."""
    if isinstance(base, dict) and isinstance(overlay, dict):
        merged = base.copy()
        for key, value in overlay.items():
            if key in merged:
                # Error on conflicts - configs should be in shared XOR profile
                raise ValueError(
                    f"Conflict: '{key}' defined in both shared and profile YAML. "
                    "Each config should be in shared OR profile-specific, not both."
                )
            merged[key] = value
        return merged
    elif isinstance(base, list) and isinstance(overlay, list):
        return base + overlay
    else:
        return overlay

def merge_yaml_files(shared_path, profile_path, output_path):
    """Merge shared and profile YAML files."""
    with open(shared_path) as f:
        shared = yaml.safe_load(f) or {}

    with open(profile_path) as f:
        profile = yaml.safe_load(f) or {}

    merged = deep_merge(shared, profile)

    with open(output_path, 'w') as f:
        yaml.dump(merged, f, default_flow_style=False, sort_keys=False)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: merge_yaml.py <shared.yaml> <profile.yaml> <output.yaml>")
        sys.exit(1)

    merge_yaml_files(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
```

### Brewfile Strategy

Run `brew bundle` twice - shared then profile:

```bash
brew bundle --file=Brewfile.shared
brew bundle --file=Brewfile.$PROFILE
```

No merging needed. `brew bundle` is idempotent, so running twice is safe and simpler than merging.

### Installation Flow (install-v2.sh)

```bash
#!/usr/bin/env bash
set -euo pipefail

# Detect profile
PROFILE=$(./scripts/detect_profile.sh)
echo "Installing dotfiles for profile: $PROFILE"

# Merge YAML files
./scripts/merge_yaml.py \
  dotfiles.shared.yaml \
  "dotfiles.${PROFILE}.yaml" \
  /tmp/dotfiles.merged.yaml

# Run existing install logic with merged YAML
# (adapt install.sh to accept --config flag)
./install.sh --config /tmp/dotfiles.merged.yaml "$@"

# Install Homebrew packages
brew bundle --file=Brewfile.shared
brew bundle --file="Brewfile.${PROFILE}"

# Cleanup
rm /tmp/dotfiles.merged.yaml
```

## Trade-offs Accepted

### Multiple Files to Maintain

Instead of one `dotfiles.yaml`, you now have three. Adding a new shared config requires editing `dotfiles.shared.yaml`, not the "main" file.

**Why acceptable:** The organizational clarity (knowing exactly what's shared vs specific) outweighs the slight inconvenience. Plus, most new configs will likely go in `shared`, making it predictable.

### Merge Complexity

The install process now requires detecting profile and merging YAML files before installation, adding a dependency on Python for YAML merging.

**Why acceptable:** The merge happens once per installation, not repeatedly. The complexity is contained in `merge_yaml.py` which you write once and forget. Python is already in use for other dotfiles tasks.

### Manual Profile Classification

When adding new configs, you must decide: shared, work, or personal? This requires thought.

**Why acceptable:** This is actually a feature - it forces explicit decisions about scope rather than implicit "works everywhere" assumptions. Most configs will be obviously shared or specific.

### Cannot Auto-Sync Work Configs

If work configs need privacy, the unified repo must either be private or work configs must be carefully managed.

**Why acceptable:** Work repo is currently private but doesn't need to be. Unified repo can start public and be made private later if needed.

### Three Brewfiles to Maintain

Same split applies to Homebrew packages - shared, work, personal.

**Why acceptable:** Running `brew bundle` twice is simple and clear. The split makes it obvious which packages are required where, preventing accidental work-only package installation on personal machines.

## Open Questions (Resolved)

### 1. Work Repo Privacy ✓

Work repo is currently private but doesn't need to be. Unified repo will start public and can be made private later if needed.

### 2. Brewfile Strategy ✓

Run `brew bundle` twice (shared then profile). No need to merge Brewfiles - running twice is simpler and clearer.

### 3. Profile Override Semantics ✓

Error loudly if work and shared define the same config. This indicates a design problem - configs should be in shared XOR profile-specific files, never both. Implemented in `merge_yaml.py`.

### 4. Existing Work Repo Migration ✓

Keep `/Users/matthew/code/bostonaholic/shopify-dotfiles` as backup. Do not modify it. Archive after successful transition.

### 5. Testing Strategy ✓

Create `install-v2.sh` and `update-v2.sh` for testing new approach alongside existing scripts. Switch once proven stable on both machines.

## Migration Path

1. **Preparation**
   - [ ] Add `.dotfiles_profile` to `.gitignore`
   - [ ] Create `scripts/detect_profile.sh`
   - [ ] Create `scripts/merge_yaml.py`
   - [ ] Make both scripts executable

2. **Split Current Config**
   - [ ] Create `dotfiles.shared.yaml` from current `dotfiles.yaml`
   - [ ] Create `dotfiles.personal.yaml` (empty initially or with personal-specific items)
   - [ ] Create `Brewfile.shared` from current `Brewfile`
   - [ ] Create `Brewfile.personal` (empty initially)

3. **Migrate Work Configs**
   - [ ] Review `/Users/matthew/code/bostonaholic/shopify-dotfiles`
   - [ ] Extract work-specific configs to `dotfiles.work.yaml`
   - [ ] Extract work-specific packages to `Brewfile.work`
   - [ ] Move shared configs from work repo to `dotfiles.shared.yaml`

4. **Create V2 Scripts**
   - [ ] Create `install-v2.sh` with profile detection and merging
   - [ ] Create `update-v2.sh` with profile detection and merging
   - [ ] Make both executable

5. **Test on Personal Machine**
   - [ ] Run `./install-v2.sh --dry-run`
   - [ ] Verify merged config is correct
   - [ ] Run `./install-v2.sh -fy`
   - [ ] Verify installation succeeds
   - [ ] Check `~/.dotfiles_profile` was created with "personal"

6. **Test on Work Machine**
   - [ ] Run `./install-v2.sh --dry-run`
   - [ ] Verify merged config is correct
   - [ ] Run `./install-v2.sh -fy`
   - [ ] Verify installation succeeds
   - [ ] Check `~/.dotfiles_profile` was created with "work"

7. **Cutover**
   - [ ] Rename `install.sh` to `install.v1.sh` (backup)
   - [ ] Rename `install-v2.sh` to `install.sh`
   - [ ] Rename `update.sh` to `update.v1.sh` (backup)
   - [ ] Rename `update-v2.sh` to `update.sh`
   - [ ] Update documentation (CLAUDE.md, README if exists)

8. **Cleanup**
   - [ ] Archive work repo (do not delete, do not modify)
   - [ ] Remove old `dotfiles.yaml` once verified
   - [ ] Remove old `Brewfile` once verified
   - [ ] Remove `*.v1.sh` backup scripts after confidence period

## Next Steps

- [ ] Research phase: Investigate existing `dotfiles.yaml` structure and work repo contents
- [ ] Planning phase: Create detailed implementation tasks
- [ ] Implementation: Execute migration path
