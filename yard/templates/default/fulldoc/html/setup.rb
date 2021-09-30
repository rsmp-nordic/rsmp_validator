def init
  super
  
  # Additional javascript that power the additional menus, collapsing, etc.
  #asset("js/rspec.js",file("js/rspec.js",true))
  asset("css/rspec.css",file("css/rspec.css",true))
  
  # Generates the specs splash page with the 'specs' template
  Templates::Engine.with_serializer(YARD::CodeObjects::RSpec::RSPEC_NAMESPACE, options.serializer) do
    T('specs').run(options)
  end

  # Generate pages for each of the specs, with the 'spec' template and then
  # generate the page which is the full list of specs
  #
  @contexts = Registry.all(:context)
  if @contexts
    @contexts.each {|context| serialize(context) }
    generate_specification_list
  end
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
  asset('specification_list.html', erb(:full_list))
end
