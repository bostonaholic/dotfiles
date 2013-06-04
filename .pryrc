Pry.prompt = [
  proc { |obj, nest_level, _|
    "#{RUBY_VERSION} (#{obj}):#{nest_level} > " },
  proc { |obj, nest_level, _|
    "#{RUBY_VERSION} (#{obj}):#{nest_level} * " }
]

Pry.editor = 'mvim'

# == Pry-Nav - Using pry as a debugger ==
Pry.commands.alias_command 'c', 'continue'
Pry.commands.alias_command 's', 'step'
Pry.commands.alias_command 'n', 'next'

begin
  require 'awesome_print'
  # The following line enables awesome_print for all pry output,
  # and it also enables paging
  Pry.config.print = proc { |output, value|
    Pry::Helpers::BaseHelpers.stagger_output("=> #{value.ai}", output)
  }

  # If you want awesome_print without automatic pagination, use the line below
  # Pry.config.print = proc { |output, value|
  #   output.puts value.ai
  # }
rescue LoadError => err
  puts "gem install awesome_print  # <-- highly recommended"
end

# === CONVENIENCE METHODS ===
# Stolen from https://gist.github.com/807492
# Use Array.toy or Hash.toy to get an array or hash to play with
class Array
  def self.toy(n=10, &block)
    block_given? ? Array.new(n,&block) : Array.new(n) {|i| i+1}
  end
end

class Hash
  def self.toy(n=10)
    Hash[Array.toy(n).zip(Array.toy(n){|c| (96+(c+1)).chr})]
  end
end
