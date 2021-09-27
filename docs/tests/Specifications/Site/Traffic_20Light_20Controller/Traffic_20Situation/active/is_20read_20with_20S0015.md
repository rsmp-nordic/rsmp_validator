---
layout: page
title: is read with S0015
parent: active
---

# active is read with S0015

Verify status S0015 current traffic situation

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "current traffic situation",
{ S0015: [:status] }
```

