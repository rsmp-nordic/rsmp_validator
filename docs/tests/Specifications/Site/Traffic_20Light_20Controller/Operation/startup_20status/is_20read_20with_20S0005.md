---
layout: page
title: is read with S0005
parent: startup status
---

# startup status is read with S0005

Verify status S0005 traffic controller starting

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "traffic controller starting (true/false)",
{ S0005: [:status] }
```

