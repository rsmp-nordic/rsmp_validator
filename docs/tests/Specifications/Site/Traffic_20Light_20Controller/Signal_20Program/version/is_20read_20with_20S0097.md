---
layout: page
title: is read with S0097
parent: version
---

# version is read with S0097

Verify status S0097 version of traffic program

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "version of traffic program",
{ S0097: [:timestamp,:checksum] }
```

