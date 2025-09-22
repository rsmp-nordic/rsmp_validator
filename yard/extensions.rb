#
# Yard extensions to generate documentation for RSpec tests.
#
# To generate documentation for tests and support methods, run:
#
# % yardoc spec
#
# If you want to generate docs only for the tests, not the support methods, run:
#
# % yardoc spec/site
#
# The output will be located in the folder you are in when you run the command.
# Use a browser to open the index.html file to view the generated documentation.
#
# Note that the file yard/extensions.rb must be included. This is done automatically
# because the ./.yardopts includes it. Otherwise it can be done on the command line, e.g:
#
#
# % yardoc -e yard/extensions.rb spec


templates_path = File.join(File.dirname(__FILE__),'templates')
YARD::Templates::Engine.register_template_path templates_path

require_relative 'code_objects/rspec'
require_relative 'code_objects/context'
require_relative 'code_objects/specification'
require_relative 'handlers/specification_handler'
