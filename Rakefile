# frozen_string_literal: true

require 'rubygems'
require 'rake'

task default: [:install]

desc 'Symlink all dot files'
task :install do
  # symlink dot files
  files = Dir.glob('.*').sort \
    - ['.', '..'] \
    - ['.git', '.gitignore', '.gitmodules'] \
    - ['.env.sample']
  symlink_files files

  # symlink bin
  # link_file 'bin', ENV['HOME'].to_s

  # symlink misc
  boot_dir = "#{ENV['HOME']}/.boot"
  Dir.mkdir boot_dir unless Dir.exist?(boot_dir)
  link_file 'boot.properties', boot_dir

  gnupg_dir = "#{ENV['HOME']}/.gnupg"
  Dir.mkdir gnupg_dir unless Dir.exist?(gnupg_dir)
  link_file 'gpg-agent.conf', gnupg_dir

  lein_dir = "#{ENV['HOME']}/.lein"
  Dir.mkdir lein_dir unless Dir.exist?(lein_dir)
  link_file 'profiles.clj', lein_dir

  link_file 'qwerty.txt', ENV['HOME'].to_s

  # symlink oh-my-zsh
  bostonaholic_plugin_dir = "#{ENV['HOME']}/.oh-my-zsh/custom/plugins/bostonaholic"
  Dir.mkdir bostonaholic_plugin_dir unless Dir.exist?(bostonaholic_plugin_dir)
  link_file 'bostonaholic.plugin.zsh', bostonaholic_plugin_dir

  nodenv_plugin_dir = "#{ENV['HOME']}/.oh-my-zsh/custom/plugins/nodenv"
  Dir.mkdir nodenv_plugin_dir unless Dir.exist?(nodenv_plugin_dir)
  link_file 'nodenv.plugin.zsh', nodenv_plugin_dir

  link_file 'msb.zsh-theme', "#{ENV['HOME']}/.oh-my-zsh/custom/themes"

  # symlink samples
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
