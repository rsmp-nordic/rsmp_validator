---
layout: page
title: is activated with M0006
parent: Input
---

# Input is activated with M0006

1. Verify connection
2. Verify that there is a Validator.config['validator'] with a input
3. Send control command to switch input
4. Wait for status "input" = requested

```ruby
inputs = Validator.config['items']['inputs']
skip("No inputs configured") if inputs.nil? || inputs.empty?
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  inputs.each { |input| switch_input input }
end
```

