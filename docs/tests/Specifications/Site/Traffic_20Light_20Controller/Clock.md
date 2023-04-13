---
layout: page
title: Clock
parmalink: traffic_light_controller_clock
has_children: false
has_toc: false
parent: Traffic Light Controller
grand_parent: Site
---

# Traffic Light Controller Clock
{: .no_toc}

Tests related to the clock.
When you set the clock, the adjusted time should be used
everywhere you get back a timestamp.

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Clock can be read with S0096

Verify status 0096 current date and time

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  request_status_and_confirm site, "current date and time",
    { S0096: [
      :year,
      :month,
      :day,
      :hour,
      :minute,
      :second,
    ] }
end
```
</details>




## Clock can be set with M0104

Verify that the controller responds to M0104

1. Given the site is connected
2. Send command
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  set_clock(CLOCK)
end
```
</details>




## Clock is used for M0001 response timestamp

Verify command response timestamp after changing clock

1. Given the site is connected
2. Send control command to set clock
3. Send command to set functional position
4. Compare set_clock and response timestamp
5. Expect the difference to be within max_diff

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  with_clock_set CLOCK do
    result = set_functional_position 'NormalControl'
    collector = result[:collector]
    max_diff = Validator.config['timeouts']['command_response'] * 2
    diff = Time.parse(collector.messages.first.attributes['cTS']) - CLOCK
    diff = diff.round
    expect(diff.abs).to be <= max_diff,
      "Timestamp of command response is off by #{diff}s, should be within #{max_diff}s"
  end
end
```
</details>




## Clock is used for M0104 response timestamp

Verify command response timestamp after changing clock

1. Given the site is connected
2. Send control command to set clock
3. Send command to set functional position
4. Compare set_clock and response timestamp
5. Expect the difference to be within max_diff

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  with_clock_set CLOCK do
    result = set_functional_position 'NormalControl'
    collector = result[:collector]
    max_diff = Validator.config['timeouts']['command_response']
    diff = Time.parse(collector.messages.first.attributes['cTS']) - CLOCK
    diff = diff.round
    expect(diff.abs).to be <= max_diff,
      "Timestamp of command response is off by #{diff}s, should be within #{max_diff}s"
  end
end
```
</details>




## Clock is used for S0096 response timestamp

Verify status response timestamp after changing clock

1. Given the site is connected
2. Send control command to set_clock
3. Request status S0096
4. Compare set_clock and response timestamp
5. Expect the difference to be within max_diff

<details markdown="block">
  <summary>
     View Source
  </summary>
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
    
    result = site.request_status Validator.config['main_component'],
      convert_status_list(status_list),
      collect!: {
        timeout: Validator.config['timeouts']['status_response']
      }
    collector = result[:collector]
    max_diff = Validator.config['timeouts']['command_response'] + Validator.config['timeouts']['status_response']
    diff = Time.parse(collector.messages.first.attributes['sTs']) - CLOCK
    diff = diff.round          
    expect(diff.abs).to be <= max_diff,
      "Timestamp of S0096 is off by #{diff}s, should be within #{max_diff}s"
  end
end
```
</details>




## Clock is used for S0096 status response

Verify status S0096 clock after changing clock

1. Given the site is connected
2. Send control command to set_clock
3. Request status S0096
4. Compare set_clock and status timestamp
5. Expect the difference to be within max_diff

<details markdown="block">
  <summary>
     View Source
  </summary>
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
    result = site.request_status Validator.config['main_component'], convert_status_list(status_list), collect!: {
      timeout: Validator.config['timeouts']['status_update']
    }
    collector = result[:collector]
    status = status_list.keys.first.to_s
    received = Time.new(
      collector.query_result( {"sCI" => status, "n" => "year"} )['s'],
      collector.query_result( {"sCI" => status, "n" => "month"} )['s'],
      collector.query_result( {"sCI" => status, "n" => "day"} )['s'],
      collector.query_result( {"sCI" => status, "n" => "hour"} )['s'],
      collector.query_result( {"sCI" => status, "n" => "minute"} )['s'],
      collector.query_result( {"sCI" => status, "n" => "second"} )['s'],
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
</details>




## Clock is used for aggregated status timestamp

Verify aggregated status response timestamp after changing clock

1. Given the site is connected
2. Send control command to set clock
3. Wait for status = true
4. Request aggregated status
5. Compare set_clock and response timestamp
6. Expect the difference to be within max_diff

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  with_clock_set CLOCK do
    result = site.request_aggregated_status Validator.config['main_component'], collect!: {
      timeout: Validator.config['timeouts']['status_response']
    }
    collector = result[:collector]
    max_diff = Validator.config['timeouts']['command_response'] + Validator.config['timeouts']['status_response']
    diff = Time.parse(collector.messages.first.attributes['aSTS']) - CLOCK
    diff = diff.round
    expect(diff.abs).to be <= max_diff,
      "Timestamp of aggregated status is off by #{diff}s, should be within #{max_diff}s"
  end
end
```
</details>




## Clock is used for alarm timestamp

Verify timestamp of alarm after changing clock

1. Given the site is connected
2. Send control command to set_clock
3. Wait for status = true
4. Trigger alarm from Script
5. Wait for alarm
6. Compare set_clock and alarm response timestamp
7. Expect the difference to be within max_diff

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
skip_unless_scripts_are_configured
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  with_clock_set CLOCK do
    component = Validator.config['components']['detector_logic'].keys.first
    with_alarm_activated do
      site.log "Waiting for alarm", level: :test
      collector = site.collect_alarms task, num: 1, timeout: Validator.config['timeouts']['alarm']
      max_diff = Validator.config['timeouts']['command_response'] + Validator.config['timeouts']['status_response']
      diff = Time.parse(collector.message.first.attributes['sTs']) - CLOCK
      diff = diff.round
      expect(diff.abs).to be <= max_diff,
        "Timestamp of alarm is off by #{diff}s, should be within #{max_diff}s"
    end
  end
end
```
</details>




## Clock is used for watchdog timestamp

Verify timestamp of watchdog after changing clock

1. Given the site is connected
2. Send control command to setset_clock
3. Wait for Watchdog
4. Compare set_clock and alarm response timestamp
5. Expect the difference to be within max_diff

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  with_clock_set CLOCK do
    log "Checking watchdog timestamp"
    collector = RSMP::Collector.new site, task:task, type: "Watchdog", num: 1, timeout: Validator.config['timeouts']['watchdog']
    collector.collect!
    max_diff = Validator.config['timeouts']['command_response'] + Validator.config['timeouts']['status_response']
    diff = Time.parse(collector.messages.first.attributes['wTs']) - CLOCK
    diff = diff.round
    expect(diff.abs).to be <= max_diff,
      "Timestamp of watchdog is off by #{diff}s, should be within #{max_diff}s"
  end
end
```
</details>


