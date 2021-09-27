---
layout: page
title: for a single detector is read with S0201
parent: on number of vehicles
---

# on number of vehicles for a single detector is read with S0201

Verify status S0201 traffic counting: number of vehicles

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "traffic counting: number of vehicles",
{ S0201: [:starttime,:vehicles] },
Validator.config['components']['detector_logic'].keys.first
```

