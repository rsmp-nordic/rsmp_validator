---
layout: page
title: for all detectors is read with S0207
parent: on occupancy
---

# on occupancy for all detectors is read with S0207

Verify status S0207 traffic counting: occupancy

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "traffic counting: occupancy",
{ S0207: [:start,:occupancy] }
```

