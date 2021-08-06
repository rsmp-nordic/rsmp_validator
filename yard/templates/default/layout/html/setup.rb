def menu_lists
  # Load the existing menus
  super + [{ 
    :type => 'specification',
    :title => 'Specifications',
    :search_title => 'Specification List'
  }]
end

def yard_default_stylesheets
  [ 'css/style.css', 'css/common.css' ]
end

def stylesheets
  css = super rescue yard_default_stylesheets
  css + [ 'css/rspec.css' ]
end
