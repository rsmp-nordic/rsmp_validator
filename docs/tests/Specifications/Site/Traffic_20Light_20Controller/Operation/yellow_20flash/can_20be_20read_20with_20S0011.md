---
layout: page
title: can be read with S0011
parent: yellow flash
---

# yellow flash can be read with S0011

Verify status S0011 yellow flash

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "yellow flash status",
{ S0011: [:status,:intersection] }
```

