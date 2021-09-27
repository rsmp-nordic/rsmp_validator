---
layout: page
title: is read with S0091
parent: operator logged in/out of OP-panel
---

# operator logged in/out of OP-panel is read with S0091

Verify status S0091 operator logged in/out OP-panel

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "operator logged in/out OP-panel",
{ S0091: [:status, :user] }
```

