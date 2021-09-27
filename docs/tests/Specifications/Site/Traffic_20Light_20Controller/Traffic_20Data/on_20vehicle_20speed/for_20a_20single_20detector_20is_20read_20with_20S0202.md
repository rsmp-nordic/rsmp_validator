---
layout: page
title: for a single detector is read with S0202
parent: on vehicle speed
---

# on vehicle speed for a single detector is read with S0202

Verify status S0202 traffic counting: vehicle speed

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "traffic counting: vehicle speed",
{ S0202: [:starttime,:speed] },
Validator.config['components']['detector_logic'].keys.first
```

