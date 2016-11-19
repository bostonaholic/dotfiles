# The New Hotness (TM)

Staying as minimal as possible with my config. I'm only adding libraries and aliases as I come across inefficiencies in my development process.

## Setup

```
$ git clone git@github.com:bostonaholic/dotfiles.git
$ cd dotfiles
$ rake # symlink all files to ~
```

Symlink non-standard configuration files

```
$ ln -s $PWD/bin ~/bin
$ ln -s $PWD/gpg-agent.conf ~/.gnupg/gpg-agent.conf
$ ln -s $PWD/launchd.conf /etc/launchd.conf
$ ln -s $PWD/profiles.clj ~/.lein/profiles.clj
```

## Dependencies

- [Homebrew](http://brew.sh/)

#### Homebrew to install them all

`$ brew tap homebrew/bundle`
`$ brew bundle`

##### ZSH as default shell

`sudo dscl . -create /Users/$USER UserShell /usr/local/bin/zsh`

##### Powerline fonts

[https://github.com/powerline/fonts](https://github.com/powerline/fonts)

##### for highlighting source in cat

`$ easy_install Pygments`

##### better pry

`$ gem install pry-plus`

##### awesome print to make pry that much better

`$ gem install awesome_print`
