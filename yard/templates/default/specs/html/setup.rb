# frozen_string_literal: true

def init
  super

  @specs = object

  sections.push :contexts
end

def contexts
  @contexts = YARD::CodeObjects::RSpec::RSPEC_NAMESPACE.children.find_all { |child| child.is_a? YARD::CodeObjects::RSpec::Context }
  erb(:contexts)
end

attr_reader :context

attr_reader :specification
