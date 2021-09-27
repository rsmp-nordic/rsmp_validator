---
layout: page
title: for all detectors is read with S0206
parent: on vehicle speed
---

# on vehicle speed for all detectors is read with S0206

Verify status S0206 traffic counting: vehicle speed

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "traffic counting: vehicle speed",
{ S0206: [:start,:speed] }
```

