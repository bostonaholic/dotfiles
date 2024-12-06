# frozen_string_literal: true

require 'rake'

source_files = {
  colors: "#{ENV['PWD']}/home/colors",
  default_gems: "#{ENV['PWD']}/ruby/default-gems",
  gitsigners: "#{ENV['PWD']}/git/allowed_signers",
  gitconfig: "#{ENV['PWD']}/git/config",
  githelpers: "#{ENV['PWD']}/git/helpers",
  gitignore: "#{ENV['PWD']}/git/ignore",
  gpg_agent_conf: "#{ENV['PWD']}/gpg/gpg-agent.conf",
  ignore: "#{ENV['PWD']}/ignore/ignore",
  rgignore: "#{ENV['PWD']}/ignore/rgignore",
  jsbeautifyrc: "#{ENV['PWD']}/javascript/jsbeautifyrc",
  jshintrc: "#{ENV['PWD']}/javascript/jshintrc",
  lein_profiles: "#{ENV['PWD']}/clojure/profiles.clj",
  node_version: "#{ENV['PWD']}/node/node-version",
  pryrc: "#{ENV['PWD']}/ruby/pryrc",
  qwerty: "#{ENV['PWD']}/keyboard/qwerty.txt",
  rspec: "#{ENV['PWD']}/ruby/rspec",
  signature: "#{ENV['PWD']}/signature/signature",
  spacemacs: "#{ENV['PWD']}/emacs/spacemacs",
  zprofile: "#{ENV['PWD']}/zsh/zprofile",
  zshrc: "#{ENV['PWD']}/zsh/zshrc"
}

target_files = {
  colors: "#{ENV['HOME']}/.colors",
  default_gems: "#{ENV['HOME']}/.rbenv/default-gems",
  gitsigners: "#{ENV['HOME']}/.config/git/allowed_signers",
  gitconfig: "#{ENV['HOME']}/.config/git/config",
  githelpers: "#{ENV['HOME']}/.config/git/helpers",
  gitignore: "#{ENV['HOME']}/.config/git/ignore",
  gpg_agent_conf: "#{ENV['HOME']}/.gnupg/gpg-agent.conf",
  ignore: "#{ENV['HOME']}/.ignore",
  rgignore: "#{ENV['HOME']}/.rgignore",
  jsbeautifyrc: "#{ENV['HOME']}/.jsbeautifyrc",
  jshintrc: "#{ENV['HOME']}/.jshintrc",
  lein_profiles: "#{ENV['HOME']}/.lein/profiles.clj",
  node_version: "#{ENV['HOME']}/.node-version",
  pryrc: "#{ENV['HOME']}/.pryrc",
  qwerty: "#{ENV['HOME']}/qwerty.txt",
  rspec: "#{ENV['HOME']}/.rspec",
  signature: "#{ENV['HOME']}/.signature",
  spacemacs: "#{ENV['HOME']}/.spacemacs",
  zprofile: "#{ENV['HOME']}/.zprofile",
  zshrc: "#{ENV['HOME']}/.zshrc"
}

tasks = %w[
  symlinks
  homebrew
  brewfile
  nodenv
  npm_packages
  rbenv_plugins
  spacemacs
  vimrc
  oh-my-zsh
  powerline_fonts
]

task default: [:install]

desc 'Install bostonaholic/dotfiles'
task :install do
  puts '---------------------------------'
  puts ' Install bostonaholic/dotfiles'
  puts " --> Type 'start'"
  puts '---------------------------------'

  tasks.each { |task| run "install:#{task}" } if response? 'start'
end

namespace :install do
  desc 'Create symlinks'
  task :symlinks do
    prompt_to_install 'symlinks'

    if response? 'y'
      message 'Symlinking files...'

      ["#{ENV['HOME']}/.config/git",
       "#{ENV['HOME']}/.lein",
       "#{ENV['HOME']}/.gnupg",
       "#{ENV['HOME']}/.rbenv"].each do |dir|
        mkdir dir unless dir_exists? dir
      end

      create_symlinks source_files, target_files
    end
  end

  desc 'Install Homebrew for managing dev packages'
  task :homebrew do
    prompt_to_install 'Homebrew'

    if response? 'y'
      message 'Installing homebrew'

      system 'bash scripts/homebrew'
    end
  end

  desc 'Install Homebrew packages'
  task :brewfile do
    prompt_to_install 'Brewfile'

    if response? 'y'
      message 'Installing Brewfile...'

      system 'brew bundle --no-lock'

      # Create a link to Emacs.app in ~/Applications
      system "osascript -e 'tell application \"Finder\" to make alias file to posix file \"/opt/homebrew/Cellar/emacs-plus@29/29.4/Emacs.app\ at POSIX file \"/Applications\" with properties {name:\"Emacs.app\"}'"
    end
  end

  desc 'Install nodenv for managing Node versions'
  task :nodenv do
    prompt_to_install 'nodenv'

    if response? 'y'
      message 'Installing nodenv...'

      system 'bash scripts/nodenv'
    end
  end

  desc 'Install NPM packages'
  task :npm_packages do
    prompt_to_install 'NPM Packages'

    if response? 'y'
      message 'Installing NPM Packages...'

      system 'bash scripts/npm'
    end
  end

  desc 'Install rbenv plugins'
  task :rbenv_plugins do
    prompt_to_install 'rbenv Plugins'

    if response? 'y'
      message 'Installing rbenv Plugins...'

      system 'bash scripts/rbenv_plugins'
    end
  end

  desc 'Install Spacemacs configuration for Emacs'
  task :spacemacs do
    prompt_to_install 'Spacemacs'

    if response? 'y'
      message 'Installing Spacemacs'

      system 'bash scripts/spacemacs'
    end
  end

  desc 'Install vimrc configuration for Vim'
  task :vimrc do
    prompt_to_install 'Vimrc'

    if response? 'y'
      message 'Installing Vimrc'

      system 'bash scripts/vimrc'

      symlink_file "#{ENV['PWD']}/vim/my_configs.vim", "#{ENV['HOME']}/.vim_runtime/my_configs.vim"
    end
  end

  desc 'Install oh-my-zsh configuration for ZSH'
  task 'oh-my-zsh' do
    prompt_to_install 'oh-my-zsh'

    if response? 'y'
      message 'Installing oh-my-zsh'

      system 'bash scripts/oh-my-zsh'

      ["#{ENV['HOME']}/.oh-my-zsh/custom/plugins/bostonaholic"].each do |dir|
        mkdir dir unless dir_exists? dir
      end

      symlink_file "#{ENV['PWD']}/zsh/bostonaholic.zsh-theme",
                   "#{ENV['HOME']}/.oh-my-zsh/custom/themes/bostonaholic.zsh-theme"
      symlink_file "#{ENV['PWD']}/zsh/bostonaholic.plugin.zsh",
                   "#{ENV['HOME']}/.oh-my-zsh/custom/plugins/bostonaholic/bostonaholic.plugin.zsh"
    end
  end

  desc 'Install Powerline Fonts'
  task :powerline_fonts do
    prompt_to_install 'Powerline Fonts'

    if response? 'y'
      message 'Installing Powerline Fonts'

      system 'bash scripts/powerline-fonts'
    end
  end
end

desc 'Update bostonaholic/dotfiles'
task :update do
  puts '---------------------------------------------'
  puts ' Update bostonaholic/dotfiles'
  puts " --> Type 'start'"
  puts '---------------------------------------------'

  system 'bash scripts/update' if response? 'start'
end

def message(string)
  puts
  puts "--> #{string}"
end

def prompt_to_install(section)
  puts
  puts '---------------------------------------------'
  puts " Ready to install #{section}? [y|N]"
  puts '---------------------------------------------'
end

def response?(value)
  $stdin.gets.chomp == value
end

def run(task)
  Rake::Task[task].invoke
end

def symlink_file(source_file, target_file)
  if file_identical? source_file, target_file
    skip_identical_file target_file
  elsif replace_all_files?
    link_file source_file, target_file
  elsif file_missing? target_file
    link_file source_file, target_file
  else
    prompt_to_link_file source_file, target_file
  end
end

# FILE CHECKS
def file_exists?(file)
  File.exist?(file)
end

def dir_exists?(dir)
  Dir.exist?(dir)
end

def file_missing?(file)
  !file_exists? file
end

def file_identical?(file_path1, file_path2)
  File.identical?(file_path1, file_path2)
end

def replace_all_files?
  @replace_all == true
end

# FILE ACTIONS
def prompt_to_link_file(source_file, target_file)
  puts
  print "overwrite? #{target_file} [ynaq]  "
  case $stdin.gets.chomp
  when 'y' then replace_file source_file, target_file
  when 'a' then replace_all source_file, target_file
  when 'q' then exit
  else skip_file target_file
  end
end

def mkdir(dir_path)
  Dir.mkdir(dir_path)
end

def link_file(source_file, destination_file)
  message "symlinking #{destination_file} to #{source_file}"
  File.symlink(source_file, destination_file)
end

def replace_file(source_file, target_file)
  `rm -rfv #{target_file}`
  link_file source_file, target_file
end

def replace_all(source_file, target_file)
  @replace_all = true
  replace_file source_file, target_file
end

def skip_file(file)
  message "skipping #{file}"
end

def skip_identical_file(file)
  message "skipping identical #{file}"
end

def create_symlinks(source_files, target_files)
  source_files.each do |source_key, source_file|
    symlink_file source_file, target_files[source_key]
  end
end
