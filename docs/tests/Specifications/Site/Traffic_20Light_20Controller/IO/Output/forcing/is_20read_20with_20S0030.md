---
layout: page
title: is read with S0030
parent: forcing
---

# forcing is read with S0030

Verify status S0030 forced output status

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "forced output status",
{ S0030: [:status] }
```

