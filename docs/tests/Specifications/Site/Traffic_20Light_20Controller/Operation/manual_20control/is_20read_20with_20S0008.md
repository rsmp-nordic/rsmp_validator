---
layout: page
title: is read with S0008
parent: manual control
---

# manual control is read with S0008

Verify status S0008 manual control

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "manual control status",
{ S0008: [:status,:intersection] }
```

