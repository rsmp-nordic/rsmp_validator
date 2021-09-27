---
layout: page
title: for a single detector is read with S0204
parent: on classification
---

# on classification for a single detector is read with S0204

Verify status S0204 traffic counting: classification

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "traffic counting: classification",
{ S0204: [
    :starttime,
    :P,
    :PS,
    :L,
    :LS,
    :B,
    :SP,
    :MC,
    :C,
    :F
] },
Validator.config['components']['detector_logic'].keys.first
```

