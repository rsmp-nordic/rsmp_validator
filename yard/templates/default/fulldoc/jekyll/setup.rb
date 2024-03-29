def init
  super
  
  sections :specifications
  # Generates the specs splash page with the 'specs' template
  #serialize(YARD::CodeObjects::RSpec::RSPEC_NAMESPACE)
  
  #
  # Generate pages for each of the specs, with the 'spec' template and then
  # generate the page which is the full list of specs
  #
  #@contexts = Registry.all(:context)
  #if @contexts
  #  @contexts.each {|context| serialize(context) }
  #  generate_specification_list
  #end
  #
end

def specifications
  'specs'
end

def generate_specification_list

  # load all the specifications from the Registry
  @items = Registry.all(:specification).sort {|x,y| x.value.to_s <=> y.value.to_s }
  @list_title = "Specification List"
  @list_type = "specification"
  
  # optional: the specified stylesheet class
  # when not specified it will default to the value of @list_type
  @list_class = "class"
  
  # Generate the full list html file with named specification_list.html
  # @note this file must be match the name of the type
  asset('specification_list.md', erb(:full_list))
end
