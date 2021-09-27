---
layout: page
title: for a single detector is read with S0203
parent: on occupancy
---

# on occupancy for a single detector is read with S0203

Verify status S0203 traffic counting: occupancy

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "traffic counting: occupancy",
{ S0203: [:starttime,:occupancy] },
Validator.config['components']['detector_logic'].keys.first
```

