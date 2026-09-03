# There's no place like ~

## Setup

### Clone the repository

```bash
git clone git@github.com:bostonaholic/dotfiles.git ~/dotfiles
```

### Copy sample environment files

```bash
cp $PWD/env/secret.sample.el $HOME/.secret.el
```

```bash
cp $PWD/env/env.sample $HOME/.env
```

### Configure a work computer

Configure git to use a work email and signing key

```bash
vi ~/.config/git/config.work
```

```plaintext
[user]
    name = Matthew Boston
    email = matthew.boston@example.com
    signingkey = <>
```

Fill in the `TODO` sections in each of the above environment files.

### Install with install.sh

```bash
# Full installation (interactive)
./install.sh

# Preview changes without making them
./install.sh --dry-run

# Install without prompts
./install.sh -y

# Install specific components only
./install.sh --only symlinks        # Only create symlinks
./install.sh --only homebrew        # Only install Homebrew packages
./install.sh --only npm             # Only install npm packages
./install.sh --only symlinks,homebrew  # Multiple components

# Other options
./install.sh -v                     # Verbose output
./install.sh -f                     # Force overwrite files
./install.sh --no-backup            # Skip backing up existing files
./install.sh --help                 # Show all options
```

The installation is now managed by a single `install.sh` script with a declarative `dotfiles.yaml` configuration file.

### Configuration with dotfiles.yaml

The `dotfiles.yaml` file controls what gets installed and where. It has three main sections:

#### Directories

Lists directories that will be created in your home folder:

```yaml
directories:
  - ~/.config/git
  - ~/.gnupg
```

#### Symlinks

Maps source files (in the dotfiles repo) to their destination (in your home directory):

```yaml
symlinks:
  zsh/zshrc: ~/.zshrc              # Links zsh/zshrc to ~/.zshrc
  git/config: ~/.config/git/config # Links git/config to ~/.config/git/config
```

#### Adding New Dotfiles

To add a new dotfile to the installation:

1. Add your file to the appropriate directory in the repo
2. Edit `dotfiles.yaml` and add an entry to the `symlinks` section
3. Run `./install.sh --only symlinks` to create just the new symlink

## Post-install

### Terminal Fonts

The primary font is **TX-02** ([Berkeley Mono](https://berkeleygraphics.com/typefaces/berkeley-mono/)),
installed manually by copying `.otf` files to `~/Library/Fonts/`. `brew bundle`
installs **Symbols Nerd Font** for icon glyphs used by the Starship prompt.

**Ghostty** handles Nerd Font symbols automatically — no extra configuration
needed.

**iTerm2** requires manual font setup:

1. Settings > Profiles > Text > Font > **"TX-02"**
2. Check **"Use a different font for non-ASCII text"**
3. Set non-ASCII font to **"Symbols Nerd Font Mono"**

### Full Disk Access (macOS privacy prompts)

macOS shows "*App* would like to access data from other apps" (or "... access
files on a network volume") whenever a coding agent launched from that app runs
`find`, `mdfind`, `claude`, `agy`, and so on. macOS attributes a child
process's file access to the app that launched it (Conductor, a terminal, an
IDE). Clicking Allow covers only that one process, there is no System Settings
toggle for it, and the next spawned command asks again.

Full Disk Access (FDA) is the durable fix. It is keyed to the app's bundle id
and code signature, so it survives updates, and it covers every process the
app spawns. Apple offers no way to grant it from a script (`tccutil` can only
reset, privacy profiles require MDM, and the TCC database is SIP-protected),
so it is a one-time manual toggle per app.

`dotfiles.yaml` lists the apps that must have FDA under `macos.full_disk_access`.
`scripts/install_macos_permissions` runs at the end of `./install.sh` (or
directly), prints `granted`, `missing`, or `unverifiable` per app, opens
System Settings on the Full Disk Access pane, and prints the steps:

1. Click **+** and add each listed app (or drag it in from Finder).
2. Make sure each app's toggle is **on**.
3. Fully quit (Cmd+Q) and relaunch the app. FDA applies only to newly launched
   processes, including the agents it spawns.
4. Re-run `scripts/install_macos_permissions`.

Status can only be verified from a terminal that already has FDA itself.
Otherwise every app reports `unverifiable` and the pane still opens.

To allowlist another app, append its `.app` path to `macos.full_disk_access`
and re-run the script. To find which app is prompting, query the unified log
(use the full path: this shell config shadows `log` with a function):

```bash
/usr/bin/log show --last 1d --style compact \
  --predicate 'process == "tccd" AND eventMessage CONTAINS "AUTHREQ_PROMPTING"'
```

`Sub:{...}` / `responsible_path=` is the app to allowlist; `binary_path=` is
the child command that tripped the check.

### Copilot.vim

```vimscript
vim -c "Copilot setup"
```

## Tips

### ssh-agent

Errors with `ssh-agent`:

> Error connecting to agent: No such file or directory

Add `zstyle :omz:plugins:ssh-agent agent-forwarding on`

### 1Password SSH Agent

```plaintext
sign_and_send_pubkey: signing failed for ED25519 "key name" from agent: communication with agent failed
git@github.com: Permission denied (publickey).
```

This happens when 1Password is locked. Unlock 1Password and verify the agent is working:

```bash
ssh-add -l
```

---

Errors with `/usr/local/bin/gpg` not in the `$PATH`

```plaintext
fatal: cannot run /usr/local/bin/gpg: No such file or directory
error: gpg failed to sign the data
fatal: failed to write commit object
```

It might be that Homebrew's version of `gpg` needs the symlink overwritten.

```bash
brew link --overwrite gnupg
```

Or

```plaintext
error: gpg failed to sign the data
fatal: failed to write commit object
```

Try:

```bash
gpgconf --kil gpg-agent
```

### vimrc

```plaintext
  File "/Users/<user>/.vim_runtime/update_plugins.py", line 13, in <module>
    import requests
ModuleNotFoundError: No module named 'requests'
```

Try:

```bash
pip3 install requests
```

### compaudit

```plaintext
zsh compinit: insecure directories, run compaudit for list.
Ignore insecure directories and continue [y] or abort compinit [n]?
```

Try:

Check which directory has the wrong permissions

```bash
compaudit
```

Then run the following to fix the permissions:

```bash
sudo chmod -R g-w <directory>
```
