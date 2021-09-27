---
layout: page
title: is read with S0022
parent: list
---

# list is read with S0022

Verify status S0022 list of time plans

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "list of time plans",
{ S0022: [:status] }
```

