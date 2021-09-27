---
layout: page
title: is read with S0029
parent: forcing
---

# forcing is read with S0029

Verify status S0029 forced input status

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "forced input status",
{ S0029: [:status] }
```

