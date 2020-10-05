# There's no place like ~

Staying as minimal as possible with my config. I'm only adding libraries and aliases as I come across inefficiencies in my development process.

## Setup

```
$ mkdir code && cd code
$ git clone git@github.com:bostonaholic/dotfiles.git
$ cd dotfiles
$ rake # symlink all files to ~
```

Symlink non-standard configuration files

```
$ ln -s $PWD/boot.properties ~/.boot/boot.properties
$ ln -s $PWD/gpg-agent.conf ~/.gnupg/gpg-agent.conf
$ ln -s $PWD/profiles.clj ~/.lein/profiles.clj
```

## Editor Configs

- [Spacemacs](https://www.spacemacs.org/)
- [The Ultimate vimrc](https://github.com/amix/vimrc)

## Dependencies

- [Homebrew](https://brew.sh)
- [GPG Suite](https://gpgtools.org/)

#### Homebrew to install them all

```
$ brew tap homebrew/bundle
$ brew bundle
```

#### ZSH as default shell

`$ chsh -s $(which zsh)`

### Configure oh-my-zsh

Install [oh-my-zsh](https://ohmyz.sh/)

Symlink my theme

```
$ ln -s $PWD/zsh/bostonaholic.zsh-theme ~/.oh-my-zsh/custom/themes/bostonaholic.zsh-theme
```

Symlink my plugin

```
$ ln -s $PWD/zsh/bostonaholic.plugin.zsh ~/.oh-my-zsh/custom/plugins/bostonaholic/bostonaholic.plugin.zsh
```

#### Powerline fonts

[https://github.com/powerline/fonts](https://github.com/powerline/fonts)

#### Tern JavaScript Analyzer

`npm install -g tern`

## Tips

Errors with `ssh-agent`:

> Error connecting to agent: No such file or directory

Add `zstyle :omz:plugins:ssh-agent agent-forwarding on`
