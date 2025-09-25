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

### Copilot.vim

```vimscript
vim -c "Copilot setup"
```

## Tips

### ssh-agent

Errors with `ssh-agent`:

> Error connecting to agent: No such file or directory

Add `zstyle :omz:plugins:ssh-agent agent-forwarding on`

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
