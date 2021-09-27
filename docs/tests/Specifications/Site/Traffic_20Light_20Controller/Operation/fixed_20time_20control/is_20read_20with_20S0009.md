---
layout: page
title: is read with S0009
parent: fixed time control
---

# fixed time control is read with S0009

Verify status S0009 fixed time control

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "fixed time control status",
{ S0009: [:status,:intersection] }
```

