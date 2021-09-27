---
layout: page
title: is ordered to green with M0010
parent: Signal Group
---

# Signal Group is ordered to green with M0010

Validate that a signal group can be ordered to green using the M0002 command.

1. Verify connection
2. Send control command to start signalgrup, set_signal_start= true, include security_code
3. Wait for status = true

```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  set_signal_start
end
```

