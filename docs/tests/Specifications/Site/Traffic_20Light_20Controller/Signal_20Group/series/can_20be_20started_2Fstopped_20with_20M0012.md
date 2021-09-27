---
layout: page
title: can be started/stopped with M0012
parent: series
---

# series can be started/stopped with M0012

1. Verify connection
2. Send control command to start or stop a serie of signalgroups
3. Wait for status = true

```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  set_signal_start_or_stop '5,4134,65;5,11'
end
```

