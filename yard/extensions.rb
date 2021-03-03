#
# Yard extensions to generate documentation for RSpec tests.
#
# To generate documentation for tests and support methods, run:
#
# % yardoc spec
#
# If you want to generate docs only for the test, not the support methods, run:
#
# %yarddoc spec/site
#
# The output will be located in the folder you are in when you run the command.
# Use a browser to open the index.html file to view the generated documentation.
#
# Note that the file yard/extensions.rb must be included. This is done automatically
# because the ./.yardopts includes it. Otherwise it can be done on the command line, e.g:
#
#
# % yardoc -e yard/extensions.rb spec


#YARD::Templates::Engine.register_template_path File.dirname(__FILE__) + '/../templates'

class RSpecDescribeHandler < YARD::Handlers::Ruby::Base
  handles method_call(:describe)
  
  def process
    describes = statement.parameters.first.jump(:string_content).source

    unless owner.is_a?(Hash)
      pwner = Hash[describes: describes, context: ""]
      parse_block(statement.last.last, owner: pwner)
    else
      describes = owner[:describes] + describes
      pwner = owner.merge(describes: describes)
      parse_block(statement.last.last, owner: pwner)
    end
  end
end

class RSpecItHandler < YARD::Handlers::Ruby::Base
  handles method_call(:it)
  
  def process
    #p statement.docstring

    name = statement.parameters.first.jump(:tstring_content, :ident).source
    object = YARD::CodeObjects::MethodObject.new(namespace, name)
    register(object)
    got = parse_block(statement.last.last, :owner => object)
  end
end
