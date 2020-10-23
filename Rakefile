# frozen_string_literal: true

require 'rake'

source_files = {
  boot_properties: "#{ENV['PWD']}/clojure/boot.properties",
  gitconfig: "#{ENV['PWD']}/git/gitconfig",
  githelpers: "#{ENV['PWD']}/git/githelpers",
  gitignore_global: "#{ENV['PWD']}/git/gitignore_global",
  gpg_agent_conf: "#{ENV['PWD']}/gpg/gpg-agent.conf",
  ignore: "#{ENV['PWD']}/ignore/ignore",
  jsbeautifyrc: "#{ENV['PWD']}/javascript/jsbeautifyrc",
  jshintrc: "#{ENV['PWD']}/javascript/jshintrc",
  lein_profiles: "#{ENV['PWD']}/clojure/profiles.clj",
  node_version: "#{ENV['PWD']}/node/node-version",
  pryrc: "#{ENV['PWD']}/ruby/pryrc",
  qwerty: "#{ENV['PWD']}/keyboard/qwerty.txt",
  rspec: "#{ENV['PWD']}/ruby/rspec",
  signature: "#{ENV['PWD']}/signature/signature",
  spacemacs: "#{ENV['PWD']}/emacs/spacemacs",
  zshrc: "#{ENV['PWD']}/zsh/zshrc"
}

target_files = {
  boot_properties: "#{ENV['HOME']}/.boot/boot.properties",
  gitconfig: "#{ENV['HOME']}/.gitconfig",
  githelpers: "#{ENV['HOME']}/.githelpers",
  gitignore_global: "#{ENV['HOME']}/.gitignore_global",
  gpg_agent_conf: "#{ENV['HOME']}/.gnupg/gpg-agent.conf",
  ignore: "#{ENV['HOME']}/.ignore",
  jsbeautifyrc: "#{ENV['HOME']}/.jsbeautifyrc",
  jshintrc: "#{ENV['HOME']}/.jshintrc",
  lein_profiles: "#{ENV['HOME']}/.lein/profiles.clj",
  node_version: "#{ENV['HOME']}/.node-version",
  pryrc: "#{ENV['HOME']}/.pryrc",
  qwerty: "#{ENV['HOME']}/qwerty.txt",
  rspec: "#{ENV['HOME']}/.rspec",
  signature: "#{ENV['HOME']}/.signature",
  spacemacs: "#{ENV['HOME']}/.spacemacs",
  zshrc: "#{ENV['HOME']}/.zshrc"
}

tasks = %w[
  git_submodules
  symlinks
  homebrew
  rbenv
  brewfile
  nodenv
  npm_packages
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

  tasks.each { |task| run "install:#{task}" } if response?('start')
end

namespace :install do
  desc 'Install Git Submodules'
  task :git_submodules do
    prompt 'Git Submodules'

    if response?('y')
      message 'Installing Git Submodules'

      system 'bash scripts/git-submodules'
    end
  end

  desc 'Create symlinks'
  task :symlinks do
    prompt 'symlinks'

    if response?('y')
      message 'Symlinking files...'
      create_symlinks source_files, target_files
    end
  end

  desc 'Install Homebrew for managing dev packages'
  task :homebrew do
    prompt 'Homebrew'

    if response?('y')
      message 'Installing homebrew'

      system 'bash scripts/homebrew'
    end
  end

  desc 'Install rbenv for managing Ruby versions'
  task :rbenv do
    prompt 'rbenv'

    if response?('y')
      message 'Installing rbenv...'

      system 'bash scripts/rbenv'
    end
  end

  desc 'Install Homebrew packages'
  task :brewfile do
    prompt 'Brewfile'

    if response?('y')
      message 'Installing Brewfile...'

      system 'brew bundle --no-lock'
    end
  end

  desc 'Install nodenv for managing Node versions'
  task :nodenv do
    prompt 'nodenv'

    if response?('y')
      message 'Installing nodenv...'

      system 'bash scripts/nodenv'
    end
  end

  desc 'Install NPM packages'
  task :npm_packages do
    prompt 'NPM Packages'

    if response?('y')
      message 'Installing NPM Packages...'

      system 'bash scripts/npm'
    end
  end

  desc 'Install Spacemacs configuration for Emacs'
  task :spacemacs do
    prompt 'Spacemacs'

    if response?('y')
      message 'Installing Spacemacs'

      system 'bash scripts/spacemacs'
    end
  end

  desc 'Install vimrc configuration for Vim'
  task 'vimrc' do
    prompt 'Vimrc'

    if response?('y')
      message 'Installing Vimrc'

      system 'bash scripts/vimrc'

      symlink_file "#{ENV['PWD']}/vim/my_configs.vim", "#{ENV['HOME']}/.vim_runtime/my_configs.vim"
    end
  end

  desc 'Install oh-my-zsh configuration for ZSH'
  task 'oh-my-zsh' do
    prompt 'oh-my-zsh'

    if response?('y')
      message 'Installing oh-my-zsh'

      system 'bash scripts/oh-my-zsh'

      symlink_file "#{ENV['PWD']}/zsh/bostonaholic.zsh-theme", "#{ENV['HOME']}/.oh-my-zsh/custom/themes/bostonaholic.zsh-theme"
      symlink_file "#{ENV['PWD']}/zsh/bostonaholic.plugin.zsh", "#{ENV['HOME']}/.oh-my-zsh/custom/plugins/bostonaholic/bostonaholic.plugin.zsh"
      symlink_file "#{ENV['PWD']}/zsh/nodenv.plugin.zsh", "#{ENV['HOME']}/.oh-my-zsh/custom/plugins/nodenv/nodenv.plugin.zsh"
    end
  end

  desc 'Install Powerline Fonts'
  task 'powerline_fonts' do
    prompt 'Powerline Fonts'

    if response?('y')
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

  system 'bash scripts/update' if response?('start')
end

def message(string)
  puts
  puts "--> #{string}"
end

def prompt(section)
  puts
  puts '---------------------------------------------'
  puts " Ready to install #{section}? [y|N]"
  puts '---------------------------------------------'
end

def response?(value)
  $stdin.gets.chomp == value ? true : false
end

def run(task)
  Rake::Task[task].invoke
end

def symlink_file(source_file, target_file)
  if file_identical?(source_file, target_file)
    skip_identical_file(target_file)
  elsif replace_all_files?
    link_file(source_file, target_file)
  elsif file_missing?(target_file)
    prompt_to_link_file(source_file, target_file)
  end
end

# FILE CHECKS
def file_exists?(file)
  File.exist?(file)
end

def file_missing?(file)
  !file_exists?(file)
end

def file_identical?(file_path1, file_path2)
  File.identical? file_path1, file_path2
end

def replace_all_files?
  @replace_all == true
end

# FILE ACTIONS
def prompt_to_link_file(source_file, target_file)
  puts
  print "overwrite? #{target_file} [ynaq]  "
  case $stdin.gets.chomp
  when 'y' then replace_file(source_file, target_file)
  when 'a' then replace_all(source_file, target_file)
  when 'q' then exit
  else skip_file(target_file)
  end
end

def link_file(source_file, destination_file)
  message "symlinking #{destination_file} to #{source_file}"
  File.symlink(source_file, destination_file)
end

def replace_file(source_file, target_file)
  `rm -rf #{target_file}`
  link_file(source_file, target_file)
end

def replace_all(source_file, target_file)
  @replace_all = true
  replace_file(source_file, target_file)
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
