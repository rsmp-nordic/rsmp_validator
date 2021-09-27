---
layout: page
title: is read with S0026
parent: week table
---

# week table is read with S0026

Verify status S0026 week time table

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "week time table",
{ S0026: [:status] }
```

