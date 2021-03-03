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
  handles method_call(:site)
  
  def process
    #p statement.docstring

    name = statement.parameters.first.jump(:tstring_content, :ident).source
    object = YARD::CodeObjects::MethodObject.new(namespace, name)
    register(object)
    got = parse_block(statement.last.last, :owner => object)
  end
end
