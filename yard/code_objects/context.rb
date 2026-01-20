module YARD
  module CodeObjects
    module RSpec
      class Context < NamespaceObject
        attr_accessor :value, :specifications, :owner, :paired_to_code_object

        def initialize(namespace, title)
          @specifications = []
          super
        end

        def type
          :context
        end

        def subcontexts
          children.find_all { |child| child.is_a?(Context) }
        end

        def unique_id
          "#{file}-#{line}".gsub(/\W/, '-')
        end

        def full_name(_options = {})
          context = parent
          parts = [name]
          while context.is_a?(Context)
            parts.unshift context.name
            context = context.parent
          end
          parts.shift if parts.size > 1
          parts.join(' ')
        end
      end
    end
  end
end
