---
layout: page
title: can be set with M0104
parent: Clock
---

# Clock can be set with M0104

Verify that the controller responds to M0104

1. Given the site is connected
2. Send command
3. Expect status response before timeout

```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  set_clock(CLOCK)
end
```

