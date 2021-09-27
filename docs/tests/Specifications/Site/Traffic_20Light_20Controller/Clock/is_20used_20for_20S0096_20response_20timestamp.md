---
layout: page
title: is used for S0096 response timestamp
parent: Clock
---

# Clock is used for S0096 response timestamp

Verify status response timestamp after changing clock

1. Given the site is connected
2. Send control command to set_clock
3. Request status S0096
4. Compare set_clock and response timestamp
5. Expect the difference to be within max_diff

```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  with_clock_set CLOCK do
    status_list = { S0096: [
      :year,
      :month,
      :day,
      :hour,
      :minute,
      :second,
    ] }
    
    request, response, messages = site.request_status Validator.config['main_component'],
      convert_status_list(status_list),
      collect: {
        timeout: Validator.config['timeouts']['status_response']
      }
    message = messages.first
    max_diff = Validator.config['timeouts']['command_response'] + Validator.config['timeouts']['status_response']
    diff = Time.parse(message.attributes['sTs']) - CLOCK
    diff = diff.round          
    expect(diff.abs).to be <= max_diff,
      "Timestamp of S0096 is off by #{diff}s, should be within #{max_diff}s"
  end
end
```

