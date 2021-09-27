---
layout: page
title: is used for alarm timestamp
parent: Clock
---

# Clock is used for alarm timestamp

Verify timestamp of alarm after changing clock

1. Given the site is connected
2. Send control command to set_clock
3. Wait for status = true
4. Trigger alarm from Script
5. Wait for alarm
6. Compare set_clock and alarm response timestamp
7. Expect the difference to be within max_diff

```ruby
Validator::Site.connected do |task,supervisor,site|
  require_scripts
  prepare task, site
  with_clock_set CLOCK do
    component = Validator.config['components']['detector_logic'].keys.first
    system(Validator.config['scripts']['activate_alarm'])
    site.log "Waiting for alarm", level: :test
    response = site.wait_for_alarm task, timeout: Validator.config['timeouts']['alarm']
    max_diff = Validator.config['timeouts']['command_response'] + Validator.config['timeouts']['status_response']
    diff = Time.parse(response.attributes['sTs']) - CLOCK
    diff = diff.round
    expect(diff.abs).to be <= max_diff,
      "Timestamp of alarm is off by #{diff}s, should be within #{max_diff}s"
  end
end
```

