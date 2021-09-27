---
layout: page
title: is read with S0027
parent: day table
---

# day table is read with S0027

Verify status S0027 time tables

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "command table",
{ S0027: [:status] }
```

