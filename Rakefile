# frozen_string_literal: true

require 'rubygems'
require 'rake'

task default: [:legacy]

desc 'Symlink all dot files'
task :install do
  # symlink dot files
  files = Dir.glob('.*').sort \
    - ['.', '..'] \
    - ['.git', '.gitignore', '.gitmodules'] \
    - ['.env.sample']
  symlink_files files

  # symlink bin
  #link_file 'bin', ENV['HOME'].to_s

  # symlink misc
  link_file 'boot.properties', "#{ENV['HOME']}/.boot"
  link_file 'gpg-agent.conf', "#{ENV['HOME']}/.gnupg"
  link_file 'profiles.clj', "#{ENV['HOME']}/.lein"
  link_file 'qwerty.txt', ENV['HOME'].to_s

  # symlink oh-my-zsh
  link_file 'msb.plugin.zsh', "#{ENV['HOME']}/.oh-my-zsh/custom/plugins/msb"
  link_file 'nodenv.plugin.zsh', "#{ENV['HOME']}/.oh-my-zsh/custom/plugins/nodenv"
  link_file 'msb.zsh-theme', "#{ENV['HOME']}/.oh-my-zsh/custom/themes"

  # symlink samples
end

desc 'symlink all dot files'
task :legacy do
  files = Dir.glob('.*') \
    + ['homefiles/bin'] \
    - ['.git', '.gitignore', '.gitmodules', '.env', '.env.sample', '.', '..']
  symlink_files files

  # files that need symlinked somewhere other than ~
  link_file 'gpg-agent.conf', "#{ENV['HOME']}/.gnupg"
end

def symlink_file(file)
  if file_identical?(file)
    skip_identical_file(file)
  elsif replace_all_files?
    link_file(file)
  elsif file_missing?(file)
    prompt_to_link_file(file)
  end
end

def symlink_files(files)
  files.each do |file|
    symlink_file file
  end
end

# FILE CHECKS
def file_exists?(file)
  File.exist?("#{ENV['HOME']}/#{file}") # FIXME
end

def file_missing?(file)
  !file_exists?(file)
end

def file_identical?(file)
  File.identical? file, File.join(ENV['HOME'], file.to_s) # FIXME
end

def replace_all_files?
  @replace_all == true
end

# FILE ACTIONS
def prompt_to_link_file(file)
  print "overwrite? ~/#{file} [ynaq]  " # FIXME
  case $stdin.gets.chomp
  when 'y' then replace_file(file)
  when 'a' then replace_all(file)
  when 'q' then exit
  else skip_file(file)
  end
end

def link_file(file, destination = ENV['HOME'])
  puts " => symlinking #{file} to #{destination}"
  directory = File.dirname(__FILE__)
  File.symlink(File.join(directory, file).to_s, "#{destination}/#{file}")
end

def replace_file(file)
  `rm -rf #{ENV['HOME']}/#{file}` # FIXME
  link_file(file)
end

def replace_all(file)
  @replace_all = true
  replace_file(file)
end

def skip_file(file)
  puts " => skipping ~/#{file}" # FIXME
end

def skip_identical_file(file)
  puts " => skipping identical ~/#{file}" # FIXME
end
