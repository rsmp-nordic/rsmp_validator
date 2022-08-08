---
layout: page
title: Alarm
parmalink: traffic_light_controller_alarm
has_children: false
has_toc: false
parent: Traffic Light Controller
grand_parent: Site
---

# Traffic Light Controller Alarm
{: .no_toc}

Alarms can be hard to validate unless you have a reliable
method of triggering them, and there is currently no way to directly triggering
alarms via RSMP.

Often some alarms can be triggered manually on the equipment,
but since the validator is meant for automated testing, this approach is
not used.

Instead a separate interface which can be scripted, like SSH,
must be used. If the equipment support this, you must set up scripts to
activate and deactive alarms. These scripts will then be used in the tests
to trigger alarms.

If you have no way of triggering the relevant alarm via a scripts, skipping
the test is recommended.

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Alarm A0302 is raised when a detector logic is faulty

Validate that a detector logic fault raises A0302.

1. Given the site is connected
2. When we trigger an alarm using an external script
3. Then we should receive ana alarm

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
skip "Don't yet have a reliable way of triggering alarms"
skip_unless_scripts_are_configured
Validator::Site.connected do |task,supervisor,site|
  component = Validator.config['components']['detector_logic'].keys.first
  with_alarm_activated do
    site.log "Waiting for alarm", level: :test
    start_time = Time.now
    alarm_code_id = 'A0301'
    collector = site.collect_alarms num: 1, component: component, aCId: alarm_code_id,
      aSp: 'Issue', aS: 'Active', timeout: Validator.config['timeouts']['alarm']
    alarm = collector.message
    delay = Time.now - start_time
    site.log "alarm confirmed after #{delay.to_i}s", level: :test
    alarm_time = Time.parse(alarm.attributes["aTs"])
    expect(alarm_time).to be_within(1.minute).of Time.now.utc
  end
end
```
</details>




## Alarm Alarm A0301 is raised when input is activated

Validate that a detector logic fault A0301 is raises and removed.

The test expects that the TLC is programmed so that an alarm
is raise when a specific input is activated. The alarm code and input nr
is read from the test configuration.

1. Given the site is connected
2. And we have forced the input to False
2. When we force the input to True
3. Then we should receive an active alarm issue, with a reasonable timestamp
4. When we force the input to False
5. Then the alarm issue should become inactive, with a reasonable timestamp

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
alarm_code_id = 'A0301'   # what alarm to expect
skip "alarm activation is not configured" unless Validator.config['alarm_activation']
input_nr = Validator.config['alarm_activation'][alarm_code_id]  # what input to activate
skip "alarm activation for alarm #{alarm_code_id}  not configured" unless input_nr

Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  timeout  = Validator.config['timeouts']['alarm']
  # first force input to false, so we're sure to get an alarm when we afterwards force to true
  force_input_and_confirm input:input_nr, value:'False'
  # the rsmp spec requires a specific casing of enums, but some equipment uses incorrect casing.
  # incorrect casing is usualle cuaght by the json schema validation, but in case this is disabled,
  # we use case-insensitive regex patterns so that the tests can still be run
  mapping = {
    'True' => /Active/i,    # when input is forced to True, the alarm should become active
    'False' => /inActive/i  # when input is forced to False, the alarm should become inactive
  }
  mapping.each_pair do |input_value, alarm_status|
    log "Check that alarm #{alarm_code_id} becomes #{alarm_status.inspect} when we force input #{input_nr} to #{input_value}"
    collect_task = task.async do  # run the collector in an async task
      collector = RSMP::AlarmCollector.new( site,
        num: 1,
        query: { 'aCId' =>  alarm_code_id, 'aSp' =>  /Issue/i, 'aS' => alarm_status },
        timeout: timeout
      )
      collector.collect!
      alarm = collector.messages.first
      alarm_time = Time.parse(alarm.attributes["aTs"])
      expect(alarm_time).to be_within(1.minute).of Time.now.utc
      log "Alarm #{alarm_code_id} is now #{alarm_status.inspect}"
    end
    force_input_and_confirm input:input_nr, value:input_value    # force the input
    collect_task.wait                                            # and wait for the collector to complete
  end
end
```
</details>




## Alarm can be acknowledged

Validate that an alarm can be acknowledged.

1. Given the site is connected
2. When we trigger an alarm using an external script
3. Then we should receive an alarm
4. When we acknowledgement the alarm
5. Then we should receive a confirmation

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
skip "Don't yet have a reliable way of triggering alarms"
skip_unless_scripts_are_configured
Validator::Site.connected do |task,supervisor,site|
  component = Validator.config['components']['detector_logic'].keys.first
  with_alarm_activated do
    site.log "Waiting for alarm", level: :test
    start_time = Time.now
    message, response = nil,nil
    alarm_code_id = 'A0301'
    collector = site.collect_alarms num: 1, component: component, aCId: alarm_code_id,
      aSp: 'Issue', aS: 'Active', timeout: Validator.config['timeouts']['alarm']
  end
  # TODO
end
```
</details>




## Alarm is buffered during disconnect

Validate that alarm triggered during a RSMP disconnect is buffered
and send once the RSMP connection is reestablished.

1. Given the site is disconnected
2. And we trigger an alarm using an external script
3. When the site reconnects
4. Then we should received an alarm

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
skip "Don't yet have a reliable way of triggering alarms"
skip_unless_scripts_are_configured
Validator::Site.stop
with_alarm_activated do
  Validator::Site.connected do |task,supervisor,site|
    component = Validator.config['components']['detector_logic'].keys.first
    log "Wait for alarm"
    collector = site.collect_alarms num: 1, component: component, aCId: 'A0302',
      aSp: 'Issue', aS: 'Active', timeout: Validator.config['timeouts']['alarm']
    alarm = collector.message
    alarm_time = Time.parse(alarm.attributes["aTs"])
    expect(alarm_time).to be_within(1.minute).of Time.now.utc
    expect(alarm.attributes['rvs']).to eq([{
      "n"=>"detector","v"=>"1"},
      {"n"=>"type","v"=>"loop"},
      {"n"=>"errormode","v"=>"on"},
      {"n"=>"manual","v"=>"True"},
      {"n"=>"logicerror","v"=>"always_off"}
    ])
  end
end
```
</details>

