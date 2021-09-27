---
layout: page
title: for all detectors is read with S0205
parent: on number of vehicles
---

# on number of vehicles for all detectors is read with S0205

Verify status S0205 traffic counting: number of vehicles

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "traffic counting: number of vehicles",
{ S0205: [:start,:vehicles] }
```

