---
layout: page
title: is read with S0001
parent: state
---

# state is read with S0001

Verify that the controller responds to S0001.

1. Given the site is connected
2. Request status
3. Expect status response before timeout

```ruby
request_status_and_confirm "signal group status",
{ S0001: [:signalgroupstatus, :cyclecounter, :basecyclecounter, :stage] }
```

