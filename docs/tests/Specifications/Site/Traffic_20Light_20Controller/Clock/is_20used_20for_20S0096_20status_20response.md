---
layout: page
title: is used for S0096 status response
parent: Clock
---

# Clock is used for S0096 status response

Verify status S0096 clock after changing clock

1. Given the site is connected
2. Send control command to set_clock
3. Request status S0096
4. Compare set_clock and status timestamp
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
    request, response = site.request_status Validator.config['main_component'], convert_status_list(status_list), collect: {
      timeout: Validator.config['timeouts']['status_update']
    }
    status = "S0096"
    received = Time.new(
      response[{"sCI" => status, "n" => "year"}]["s"],
      response[{"sCI" => status, "n" => "month"}]["s"],
      response[{"sCI" => status, "n" => "day"}]["s"],
      response[{"sCI" => status, "n" => "hour"}]["s"],
      response[{"sCI" => status, "n" => "minute"}]["s"],
      response[{"sCI" => status, "n" => "second"}]["s"],
      'UTC'
    )
    max_diff =
      Validator.config['timeouts']['command_response'] + 
      Validator.config['timeouts']['status_response']
    diff = received - CLOCK
    diff = diff.round
    expect(diff.abs).to be <= max_diff, 
      "Clock reported by S0096 is off by #{diff}s, should be within #{max_diff}s"
  end
end
```

