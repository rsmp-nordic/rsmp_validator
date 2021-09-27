---
layout: page
title: is read with S0006
parent: emergency stage
---

# emergency stage is read with S0006

Verify status S0006 emergency stage

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "emergency stage status",
{ S0006: [:status,:emergencystage] }
```

