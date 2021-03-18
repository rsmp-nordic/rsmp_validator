
module YARD::CodeObjects
  module RSpec
    
    class Specs < YARD::CodeObjects::NamespaceObject
   	end
    
    RSPEC_NAMESPACE = Specs.new(:root, "Specifications") unless defined?(RSPEC_NAMESPACE)
  end
end