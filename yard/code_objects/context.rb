module YARD::CodeObjects
  module RSpec
    class Context < NamespaceObject
      attr_accessor :value, :specifications, :owner, :paired_to_code_object

      def initialize(namespace,title)
        @specifications = []
        super(namespace,title)
      end

      def type
        :context
      end

      def subcontexts
        children.find_all {|child| child.is_a?(Context) }
      end

      def unique_id
        "#{file}-#{line}".gsub(/\W/,'-')
      end

      def full_name options={}
        context = parent
        parts = [name]
        while context.is_a?(Context)
          parts.unshift context.name
          context = context.parent
        end
        parts.shift if parts.size > 1
        parts.join(' ')
      end

      def permalink
        full_name.gsub(' ', '_').downcase
      end

      def link
        context = parent
        parts = [name]
        while context.is_a?(Context)
          parts.unshift context.name
          context = context.parent
        end
        "Tests/Specifications/" + parts.join('/').gsub(' ', '_20') + '.md'
      end
    end
  end
end