---
layout: page
title: can be requested
parent: Aggregated Status
---

# Aggregated Status can be requested

Verify that the controller responds to an aggregated status request.

1. Given the site is connected
2. Request aggregated status 
3. Expect aggregated status response before timeout

```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  log_confirmation "request aggregated status" do
    site.request_aggregated_status Validator.config['main_component'], collect: {
      timeout: Validator.config['timeouts']['status_response']
    }
  end
end
```

