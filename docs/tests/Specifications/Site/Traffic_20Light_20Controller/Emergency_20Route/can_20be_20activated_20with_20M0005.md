---
layout: page
title: can be activated with M0005
parent: Emergency Route
---

# Emergency Route can be activated with M0005

1. Verify connection
2. Verify that there is a Validator.config['validator'] with a  emergency_route
3. Send control command to switch emergency_route
4. Wait for status "emergency_route" = requested

```ruby
emergency_routes = Validator.config['items']['emergency_routes']
skip("No emergency routes configured") if emergency_routes.nil? || emergency_routes.empty?
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  emergency_routes.each { |emergency_route| switch_emergency_route emergency_route.to_s }
end
```

