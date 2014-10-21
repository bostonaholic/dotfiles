# The New Hotness (TM)

Staying as minimal as possible with my config. I'm only adding libraries and aliases as I come across inefficiencies in my development process.

## Setup

```
$ git clone git@github.com:bostonaholic/dotfiles.git
$ cd dotfiles
$ rake # symlink all files to ~
```

## Dependencies

- Xcode Command Line Tools
- Homebrew
- Rbenv

##### ZSH as default shell

`$ vi /etc/shells`
`$ chsh -s /bin/zsh`

#### Homebrew to install them all

`$ brew bundle`

##### for highlighting source in cat

`$ easy_install Pygments`

##### better pry

`$ gem install pry-plus`

##### awesome print to make pry that much better

`$ gem install awesome_print`
