---
layout: page
title: is read with S0010
parent: isolated control
---

# isolated control is read with S0010

Verify status S0010 isolated control

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "isolated control status",
{ S0010: [:status,:intersection] }
```

