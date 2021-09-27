---
layout: page
title: can be activated with M0007
parent: fixed time control
---

# fixed time control can be activated with M0007

1. Verify connection
2. Send the control command to switch to  fixed time= true
3. Wait for status = true
4. Send control command to switch "fixed time"= true
5. Wait for status = false

```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  switch_fixed_time 'True'
  switch_fixed_time 'False'
end
```

