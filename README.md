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
$ ln -s $PWD/profiles.clj ~/.lein/profiles.clj
$ ln -s $PWD/boot.properties ~/.boot/boot.properties
$ ln -s $PWD/gpg-agent.conf ~/.gnupg/gpg-agent.conf
```

## Dependencies

- [Homebrew](https://brew.sh)
- [GPG Suite](https://gpgtools.org/)

#### Homebrew to install them all

```
$ brew tap homebrew/bundle
$ brew bundle
```

##### ZSH as default shell

`$ chsh -s $(which zsh)`

##### Powerline fonts

[https://github.com/powerline/fonts](https://github.com/powerline/fonts)

#### Tern JavaScript Analyzer

`npm install -g tern`
