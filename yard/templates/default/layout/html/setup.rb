def menu_lists
  # Load the existing menus
  super + [ { :type => 'feature', :title => 'Features', :search_title => 'Feature List' } ]
end