# frozen_string_literal: true

require 'rake'

source_files = {
  gitconfig:  "#{ENV['PWD']}/git/gitconfig",
  githelpers: "#{ENV['PWD']}/git/githelpers",
  gitignore_global: "#{ENV['PWD']}/git/gitignore_global",
  ignore: "#{ENV['PWD']}/ignore/ignore",
  pryrc: "#{ENV['PWD']}/pryrc/pryrc",
  node_version: "#{ENV['PWD']}/node/node-version",
  rspec: "#{ENV['PWD']}/ruby/rspec",
  ruby_version: "#{ENV['PWD']}/ruby/ruby-version",
  signature: "#{ENV['PWD']}/signature/signature",
  spacemacs: "#{ENV['PWD']}/spacemacs/spacemacs",
  zshrc: "#{ENV['PWD']}/zsh/zshrc"
}

target_files = {
  gitconfig:  "#{ENV['HOME']}/.gitconfig",
  githelpers: "#{ENV['HOME']}/.githelpers",
  gitignore_global: "#{ENV['HOME']}/.gitignore_global",
  ignore: "#{ENV['HOME']}/.ignore",
  pryrc: "#{ENV['HOME']}/.pryrc",
  node_version: "#{ENV['HOME']}/.node-version",
  rspec: "#{ENV['HOME']}/.rspec",
  ruby_version: "#{ENV['HOME']}/.ruby-version",
  signature: "#{ENV['HOME']}/.signature",
  spacemacs: "#{ENV['HOME']}/.spacemacs",
  zshrc: "#{ENV['HOME']}/.zshrc"
}

tasks = [
  'git_submodules',
  'symlinks',
  'homebrew',
  'rbenv',
  'brewfile',
  'nodenv',
  'npm_packages',
  'spacemacs',
  'vimrc',
  'oh-my-zsh',
  'powerline_fonts'
]

task default: [:install]

desc 'Install bostonaholic/dotfiles'
task :install do
  puts '---------------------------------'
  puts ' Install bostonaholic/dotfiles'
  puts " --> Type 'start'"
  puts '---------------------------------'

  if response?('start')
    tasks.each { |task| run "install:#{task}" }
  end
end

namespace :install do
  desc 'Install Git Submodules'
  task :git_submodules do
    prompt 'submodules'

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
    prompt 'homebrew'

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

  desc 'Install the Brewfile'
  task :brewfile do
    prompt 'brewfile'

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
    prompt 'spacemacs'

    if response?('y')
      message 'Installing Spacemacs'

      system 'bash scripts/spacemacs'
    end
  end

  desc 'Install vimrc configuration for Vim'
  task 'vimrc' do
    prompt 'vimrc'

    if response?('y')
      message 'Installing vimrc'

      system 'bash scripts/vimrc'
    end
  end

  desc 'Install oh-my-zsh configuration for ZSH'
  task 'oh-my-zsh' do
    prompt 'oh-my-zsh'

    if response?('y')
      message 'Installing oh-my-zsh'

      system 'bash scripts/oh-my-zsh'
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

  if response?('start')
    system 'bash scripts/update'
  end
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
  STDIN.gets.chomp == value ? true : false
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
  print "overwrite? #{target_file} [ynaq]  "
  case STDIN.gets.chomp
  when 'y' then replace_file(source_file, target_file)
  when 'a' then replace_all(source_file, target_file)
  when 'q' then exit
  else skip_file(target_file)
  end
end

def link_file(source_file, destination_file)
  message "symlinking #{source_file} to #{destination_file}"
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
