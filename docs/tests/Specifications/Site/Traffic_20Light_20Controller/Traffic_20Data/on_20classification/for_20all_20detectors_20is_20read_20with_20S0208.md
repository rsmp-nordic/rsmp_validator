---
layout: page
title: for all detectors is read with S0208
parent: on classification
---

# on classification for all detectors is read with S0208

Verify status S0208 traffic counting: classification

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "traffic counting: classification",
{ S0208: [
    :start,
    :P,
    :PS,
    :L,
    :LS,
    :B,
    :SP,
    :MC,
    :C,
    :F
] }
```

