module YARD::CodeObjects
  module RSpec
    class Specs < YARD::CodeObjects::NamespaceObject
      def type
        :rspec
      end
    end
    RSPEC_NAMESPACE = Specs.new(:root, 'Specifications') unless defined?(RSPEC_NAMESPACE)
  end
end
