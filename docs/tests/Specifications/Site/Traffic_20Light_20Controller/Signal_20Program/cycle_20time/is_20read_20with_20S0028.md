---
layout: page
title: is read with S0028
parent: cycle time
---

# cycle time is read with S0028

Verify status S0028 cycle time

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "cycle time",
{ S0028: [:status] }
```

