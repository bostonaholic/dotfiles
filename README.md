# There's no place like ~

## Setup

### Clone the repository

```
$ mkdir code && cd code
$ git clone git@github.com:bostonaholic/dotfiles.git
```

### Copy sample environment files

```
$ cp $PWD/env/secret.sample.el $HOME/.secret.el
$ cp $PWD/env/env.sample $HOME/.env
```

### Configure a work computer

Configure git to use a work email and signing key

```
$ vi ~/.config/git/config.work
```

```
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
./install.sh --only brew            # Only install Homebrew packages
./install.sh --only npm             # Only install npm packages
./install.sh --only symlinks,brew   # Multiple components

# Other options
./install.sh -v                     # Verbose output
./install.sh -f                     # Force overwrite files
./install.sh --no-backup            # Skip backing up existing files
./install.sh --help                 # Show all options
```

The installation is now managed by a single `install.sh` script with a declarative `dotfiles.yaml` configuration file.

## Post-install

### Copilot.vim

```
vim -c "Copilot setup"
```

## Tips

### ssh-agent

Errors with `ssh-agent`:

> Error connecting to agent: No such file or directory

Add `zstyle :omz:plugins:ssh-agent agent-forwarding on`

---

Errors with `/usr/local/bin/gpg` not in the `$PATH`

```
fatal: cannot run /usr/local/bin/gpg: No such file or directory
error: gpg failed to sign the data
fatal: failed to write commit object
```

It might be that Homebrew's version of `gpg` needs the symlink overwritten.

```
brew link --overwrite gnupg
```

Or

```
error: gpg failed to sign the data
fatal: failed to write commit object
```

Try:

```
gpgconf --kil gpg-agent
```

### vimrc

```
  File "/Users/<user>/.vim_runtime/update_plugins.py", line 13, in <module>
    import requests
ModuleNotFoundError: No module named 'requests'
```

Try:

```
pip3 install requests
```

### compaudit

```
zsh compinit: insecure directories, run compaudit for list.
Ignore insecure directories and continue [y] or abort compinit [n]?
```

Try:

Check which directory has the wrong permissions

```
compaudit
```

Then run the following to fix the permissions:

```
sudo chmod -R g-w <directory>
```

## Thanks

Inspired by [drewbarontini/dotfiles](https://github.com/drewbarontini/dotfiles).
