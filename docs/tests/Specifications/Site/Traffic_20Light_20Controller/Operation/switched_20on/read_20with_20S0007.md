---
layout: page
title: read with S0007
parent: switched on
---

# switched on read with S0007

Verify status S0007 controller switched on (dark mode=off)

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "controller switch on (dark mode=off)",
{ S0007: [:status,:intersection] }
```

