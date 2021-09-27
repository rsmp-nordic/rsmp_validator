---
layout: page
title: is read with S0020
parent: control mode
---

# control mode is read with S0020

Verify status S0020 control mode

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "control mode",
{ S0020: [:controlmode,:intersection] }
```

