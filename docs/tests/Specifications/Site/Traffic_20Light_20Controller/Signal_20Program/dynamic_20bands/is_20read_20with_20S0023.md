---
layout: page
title: is read with S0023
parent: dynamic bands
---

# dynamic bands is read with S0023

Verify status S0023 command table

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "command table",
{ S0023: [:status] }
```

