---
layout: page
title: can be activated with M0001
parent: dark mode
---

# dark mode can be activated with M0001

Verify that we can activate dark mode

1. Given the site is connected
2. Send the control command to switch todarkmode
3. Wait for status"Controller on" = false
4. Send command to switch to normal control
5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"

```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  switch_dark_mode
  switch_normal_control
end
```

