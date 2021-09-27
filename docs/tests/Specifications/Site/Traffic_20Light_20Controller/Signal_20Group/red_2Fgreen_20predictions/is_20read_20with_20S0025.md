---
layout: page
title: is read with S0025
parent: red/green predictions
---

# red/green predictions is read with S0025

Verify status S0025 time-of-green/time-of-red

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "time-of-green/time-of-red",
{ S0025: [
    :minToGEstimate,
    :maxToGEstimate,
    :likelyToGEstimate,
    :ToGConfidence,
    :minToREstimate,
    :maxToREstimate,
    :likelyToREstimate
] },
Validator.config['components']['signal_group'].keys.first
```

