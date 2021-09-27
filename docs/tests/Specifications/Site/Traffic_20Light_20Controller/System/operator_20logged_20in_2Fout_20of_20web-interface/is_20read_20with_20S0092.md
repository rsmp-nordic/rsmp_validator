---
layout: page
title: is read with S0092
parent: operator logged in/out of web-interface
---

# operator logged in/out of web-interface is read with S0092

Verify status S0092 operator logged in/out web-interface

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "operator logged in/out web-interface",
{ S0092: [:status, :user] }
```

