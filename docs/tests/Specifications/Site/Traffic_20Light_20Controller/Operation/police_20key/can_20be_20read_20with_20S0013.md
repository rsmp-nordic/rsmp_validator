---
layout: page
title: can be read with S0013
parent: police key
---

# police key can be read with S0013

Verify status S0013 police key

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "police key",
{ S0013: [:status] }
```

