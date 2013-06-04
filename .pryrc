Pry.editor = 'mvim'

Pry.prompt = [
  proc { |obj, nest_level, _|
    "#{RUBY_VERSION} (#{obj}):#{nest_level} > " },
  proc { |obj, nest_level, _|
    "#{RUBY_VERSION} (#{obj}):#{nest_level} * " }
]

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
