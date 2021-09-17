module YARD::CodeObjects
  module RSpec
    class Specification < Base
      attr_accessor :value, :source

      def initialize(namespace,name)
        super(namespace,name)
      end

      def type
        :specification
      end

      def unique_id
        "#{file}-#{line}".gsub(/\W/,'-')
      end

      def full_name
        context = parent
        parts = ["**#{name}**"]
        while context.is_a?(Context)
          parts.unshift context.name
          context = context.parent
        end
        parts.join ' '
      end    
    end
  end
end
