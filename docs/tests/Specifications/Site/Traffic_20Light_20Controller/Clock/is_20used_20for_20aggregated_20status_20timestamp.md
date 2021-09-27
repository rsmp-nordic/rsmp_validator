---
layout: page
title: is used for aggregated status timestamp
parent: Clock
---

# Clock is used for aggregated status timestamp

Verify aggregated status response timestamp after changing clock

1. Given the site is connected
2. Send control command to set clock
3. Wait for status = true
4. Request aggregated status
5. Compare set_clock and response timestamp
6. Expect the difference to be within max_diff

```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  with_clock_set CLOCK do
    request, response = site.request_aggregated_status Validator.config['main_component'], collect: {
      timeout: Validator.config['timeouts']['status_response']
    }
    max_diff = Validator.config['timeouts']['command_response'] + Validator.config['timeouts']['status_response']
    diff = Time.parse(response.attributes['aSTS']) - CLOCK
    diff = diff.round
    expect(diff.abs).to be <= max_diff,
      "Timestamp of aggregated status is off by #{diff}s, should be within #{max_diff}s"
  end
end
```

