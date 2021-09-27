---
layout: page
title: can be read with S0012
parent: all red
---

# all red can be read with S0012

Verify status S0012 all red

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "all-red status",
{ S0012: [:status,:intersection] }
```

