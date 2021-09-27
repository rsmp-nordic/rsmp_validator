---
layout: page
title: is ordered to red with M0011
parent: Signal Group
---

# Signal Group is ordered to red with M0011

1. Verify connection
2. Send control command to stop signalgrup, set_signal_start= false, include security_code
3. Wait for status = true

```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  set_signal_stop
end
```

