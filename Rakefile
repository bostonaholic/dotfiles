# frozen_string_literal: true

require 'rake'

tasks = [
  'symlinks',
  'homebrew',
  'rbenv',
  'brewfile',
  'spacemacs',
  'vimrc'
]

task default: [:install]

desc 'Install bostonaholic/dotfiles'
task :install do
  puts '---------------------------------'
  puts ' Install bostonaholic/dotfiles'
  puts " --> Type 'start'"
  puts '---------------------------------'

  if response?('start')
    tasks.each { |task| Rake::Task["install:#{task}"].invoke }
  end
end

namespace :install do
  desc 'Create symlinks'
  task :symlinks do
    prompt 'symlinks'

    if response?('y')
      message 'Symlinking files...'
      create_symlinks
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

      system 'brew bundle'
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
end

def message(string)
  puts
  puts "--> #{string}"
end

def prompt(section)
  puts
  puts '---------------------------------------------'
  puts " Ready to install #{section}? [y|n]"
  puts '---------------------------------------------'
end

def response?(value)
  STDIN.gets.chomp == value ? true : false
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

def files_to_symlink
  Dir.glob('.*').sort \
    - ['.', '..'] \
    - ['.git', '.gitignore', '.gitmodules'] \
    - ['.bundle']
end

def create_symlinks
  files_to_symlink.each do |file|
    source_file = "#{ENV['PWD']}/#{file}"
    target_file = "#{ENV['HOME']}/#{file}"

    symlink_file source_file, target_file
  end
end
