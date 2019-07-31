# frozen_string_literal: true

require 'rubygems'
require 'rake'

desc 'symlink all dot files'
task :default do
  files = Dir.glob('.*') \
    + ['bin', 'gpg-agent.conf'] \
    - ['.git', '.gitmodules', '.', '..']
  symlink_files files
end

def symlink_files(files)
  files.each do |file|
    if file_identical?(file)
      skip_identical_file(file)
    elsif replace_all_files?
      link_file(file)
    elsif file_missing?(file)
      prompt_to_link_file(file)
    end
  end
end

# FILE CHECKS
def file_exists?(file)
  File.exist?("#{ENV['HOME']}/#{file}")
end

def file_missing?(file)
  !file_exists?(file)
end

def file_identical?(file)
  File.identical? file, File.join(ENV['HOME'], file.to_s)
end

def replace_all_files?
  @replace_all == true
end

# FILE ACTIONS
def prompt_to_link_file(file)
  print "overwrite? ~/#{file} [ynaq]  "
  case $stdin.gets.chomp
  when 'y' then replace_file(file)
  when 'a' then replace_all(file)
  when 'q' then exit
  else skip_file(file)
  end
end

def link_file(file)
  puts " => symlinking #{file}"
  directory = File.dirname(__FILE__)
  File.symlink(File.join(directory, file).to_s, "#{ENV['HOME']}/#{file}")
end

def replace_file(file)
  `rm -rf #{ENV['HOME']}/#{file}`
  link_file(file)
end

def replace_all(file)
  @replace_all = true
  replace_file(file)
end

def skip_file(file)
  puts " => skipping ~/#{file}"
end

def skip_identical_file(file)
  puts " => skipping identical ~/#{file}"
end
