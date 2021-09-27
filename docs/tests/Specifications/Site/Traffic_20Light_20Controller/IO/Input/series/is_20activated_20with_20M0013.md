---
layout: page
title: is activated with M0013
parent: series
---

# series is activated with M0013

1. Verify connection
2. Send control command to set a serie of input
3. Wait for status = true

```ruby
Validator::Site.connected do |task,supervisor,site|
  status = "5,4134,65;511"
  prepare task, site
  set_series_of_inputs status
end
```

