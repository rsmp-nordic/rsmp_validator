class RSpecDescribeHandler < YARD::Handlers::Ruby::Base
  handles method_call(:describe)
  
  def process
    title = statement.parameters.first.jump(:string_content).source
    
    if owner.is_a? YARD::CodeObjects::RSpec::Context
      context_owner = owner
    else
      # nest rspec contexts.
      # root context are placed inside RSPEC_NAMESPACE,
      # so that they will be shown grouped in the docs namespace list
      context_owner = YARD::CodeObjects::RSpec::RSPEC_NAMESPACE
    end

    context_object = YARD::CodeObjects::RSpec::Context.new(context_owner,title) do |context|
      context.value = title
      context.owner = context_owner
      context.add_file(statement.file,statement.line)
    end

    parse_block(statement.last.last, owner: context_object)
  end
end

class RSpecItHandler < YARD::Handlers::Ruby::Base
  handles method_call(:it)
  
  def process
    title = statement.parameters.first.jump(:tstring_content, :ident).source

    if owner.is_a?(YARD::CodeObjects::RSpec::Context)
      object = YARD::CodeObjects::RSpec::Specification.new(owner,title) do |spec|
        spec.value = title
        spec.source = statement.last.last.source.chomp
        spec.add_file(statement.file,statement.line)
      end

      owner.specifications << object
      register(object)
    end

  end
end
