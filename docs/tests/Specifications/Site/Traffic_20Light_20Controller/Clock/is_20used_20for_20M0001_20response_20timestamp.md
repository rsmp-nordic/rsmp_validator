---
layout: page
title: is used for M0001 response timestamp
parent: Clock
---

# Clock is used for M0001 response timestamp

Verify command response timestamp after changing clock

1. Given the site is connected
2. Send control command to set clock
3. Send command to set functional position
4. Compare set_clock and response timestamp
5. Expect the difference to be within max_diff

```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  with_clock_set CLOCK do
    request, response, messages = set_functional_position 'NormalControl'
    message = messages.first
    max_diff = Validator.config['timeouts']['command_response'] * 2
    diff = Time.parse(message.attributes['cTS']) - CLOCK
    diff = diff.round
    expect(diff.abs).to be <= max_diff,
      "Timestamp of command response is off by #{diff}s, should be within #{max_diff}s"
  end
end
```

