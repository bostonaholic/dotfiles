# There's no place like ~

## Setup

### Clone the repository

```
$ mkdir code && cd code
$ git clone git@github.com:bostonaholic/dotfiles.git
```

### Include the git submodules

```
$ git submodule init
$ git submodule update
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

### Install with rake

```
rake install                  # Install bostonaholic/dotfiles
rake install:brewfile         # Install Homebrew packages
rake install:homebrew         # Install Homebrew for managing dev packages
rake install:npm_packages     # Install NPM packages
rake install:oh-my-zsh        # Install oh-my-zsh configuration for ZSH
rake install:powerline_fonts  # Install Powerline Fonts
rake install:spacemacs        # Install Spacemacs configuration for Emacs
rake install:symlinks         # Create symlinks
rake install:vimrc            # Install vimrc configuration for Vim
rake update                   # Update bostonaholic/dotfiles
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

## Thanks

Inspired by [drewbarontini/dotfiles](https://github.com/drewbarontini/dotfiles).
