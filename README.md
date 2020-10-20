# There's no place like ~

## Setup

### Clone repository

```
$ mkdir code && cd code
$ git clone git@github.com:bostonaholic/dotfiles.git
```

Symlink non-standard configuration files

```
$ ln -s $PWD/boot.properties ~/.boot/boot.properties
$ ln -s $PWD/gpg-agent.conf ~/.gnupg/gpg-agent.conf
$ ln -s $PWD/profiles.clj ~/.lein/profiles.clj
```

```
$ cp $PWD/secret.sample.el $HOME/.secret.el
```

- [GPG Suite](https://gpgtools.org/)

### Symlink my oh-my-zsh theme

```
$ ln -s $PWD/zsh/bostonaholic.zsh-theme ~/.oh-my-zsh/custom/themes/bostonaholic.zsh-theme
```

Symlink my plugin

```
$ ln -s $PWD/zsh/bostonaholic.plugin.zsh ~/.oh-my-zsh/custom/plugins/bostonaholic/bostonaholic.plugin.zsh
```

## Tips

Errors with `ssh-agent`:

> Error connecting to agent: No such file or directory

Add `zstyle :omz:plugins:ssh-agent agent-forwarding on`
