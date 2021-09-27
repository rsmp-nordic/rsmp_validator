---
layout: page
title: is read with S0014
parent: running
---

# running is read with S0014

Verify status S0014 current time plan

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "current time plan",
{ S0014: [:status] }
```

