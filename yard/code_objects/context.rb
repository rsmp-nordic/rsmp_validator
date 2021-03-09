module YARD::CodeObjects
  module RSpec
    
    class Context < NamespaceObject
    
      attr_accessor :value, :specifications, :owner, :paired_to_code_object
    
      def initialize(namespace,title)
        @specifications = []
        super(namespace,title)
      end
      
      def subcontexts
        children.find_all {|child| child.is_a?(Context) }
      end
      
      def unique_id
        "#{file}-#{line}".gsub(/\W/,'-')
      end
      
    end
    
  end
end