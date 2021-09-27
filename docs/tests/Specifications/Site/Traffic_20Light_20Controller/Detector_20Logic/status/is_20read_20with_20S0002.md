---
layout: page
title: is read with S0002
parent: status
---

# status is read with S0002

Verify status S0002 detector logic status

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "detector logic status",
{ S0002: [:detectorlogicstatus] }
```

