 def generate_feature_list

   # load all the features from the Registry
   @items = Registry.all(:feature)
   @list_title = "Feature List"
   @list_type = "feature"

   # optional: the specified stylesheet class
   # when not specified it will default to the value of @list_type
   @list_class = "class"

   # Generate the full list html file with named feature_list.html
   # @note this file must be match the name of the type
   asset('feature_list.html', erb(:full_list))
 end
