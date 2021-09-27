---
layout: page
title: is used for watchdog timestamp
parent: Clock
---

# Clock is used for watchdog timestamp

Verify timestamp of watchdog after changing clock

1. Given the site is connected
2. Send control command to setset_clock
3. Wait for Watchdog
4. Compare set_clock and alarm response timestamp
5. Expect the difference to be within max_diff

```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  with_clock_set CLOCK do
    Validator.log "Checking watchdog timestamp", level: :test
    response = site.collect task, type: "Watchdog", num: 1, timeout: Validator.config['timeouts']['watchdog']
    max_diff = Validator.config['timeouts']['command_response'] + Validator.config['timeouts']['status_response']
    diff = Time.parse(response.attributes['wTs']) - CLOCK
    diff = diff.round
    expect(diff.abs).to be <= max_diff,
      "Timestamp of watchdog is off by #{diff}s, should be within #{max_diff}s"
  end
end
```

