---
layout: page
title: is read with S0024
parent: offset
---

# offset is read with S0024

Verify status S0024 offset time

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "offset time",
{ S0024: [:status] }
```

