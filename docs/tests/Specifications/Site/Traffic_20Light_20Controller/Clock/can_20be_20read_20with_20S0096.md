---
layout: page
title: can be read with S0096
parent: Clock
---

# Clock can be read with S0096

Verify status 0096 current date and time

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "current date and time",
{ S0096: [
  :year,
  :month,
  :day,
  :hour,
  :minute,
  :second,
] }
```

