# frozen_string_literal: true

# Class that handles RSpec 'describe' blocks and builds
# CodeObjects::RSpec::Context objects
class RSpecDescribeHandler < YARD::Handlers::Ruby::Base
  handles method_call(:describe)

  # process an RSpec 'describe' block
  def process
    title = statement.parameters.first.jump(:string_content).source

    # nest rspec contexts
    # root context are placed inside RSPEC_NAMESPACE,
    # so that they will be grouped in the docs namespace list
    context_owner = if owner.is_a? YARD::CodeObjects::RSpec::Context
                      owner
                    else
                      YARD::CodeObjects::RSpec::RSPEC_NAMESPACE
                    end

    object = YARD::CodeObjects::RSpec::Context.new(context_owner, title) do |context|
      context.add_file(statement.file, statement.line)
    end
    register(object)
    parse_block(statement.last.last, owner: object)
  end
end

# Class that handles  RSpec 'it' blocks and builds
# CodeObjects::RSpec::Specification
class RSpecItHandler < YARD::Handlers::Ruby::Base
  handles method_call(:it)
  handles method_call(:specify)

  # process an RSpec 'it' block (RSpec example/test specification)
  def process
    title = statement.parameters.first.jump(:tstring_content, :ident).source

    # build Specification object
    # owner must be an RSpec::Context
    return unless owner.is_a?(YARD::CodeObjects::RSpec::Context)

    object = YARD::CodeObjects::RSpec::Specification.new(owner, title) do |spec|
      spec.source = statement.last.last.source.chomp
      spec.add_file(statement.file, statement.line)
    end
    owner.specifications << object # add spec to context
    register(object)
  end
end
