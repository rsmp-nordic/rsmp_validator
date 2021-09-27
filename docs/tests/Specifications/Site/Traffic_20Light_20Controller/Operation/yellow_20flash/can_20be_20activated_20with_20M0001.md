---
layout: page
title: can be activated with M0001
parent: yellow flash
---

# yellow flash can be activated with M0001

Verify that we can activate yellow flash

1. Given the site is connected
2. Send the control command to switch to Yellow flash
3. Wait for status Yellow flash
4. Send command to switch to normal control
5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"

```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  switch_yellow_flash
  switch_normal_control
end
```

