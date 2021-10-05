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

{{ site.base_url }}
Alarms can be hard to validate unless you have a reliable
method of triggering them, and there is currently no way to directly triggering
alarms via RSMP.

Often some alarms can be triggered manually on the equipment,
but since the validator is meant for automated testing, the this approach is
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
require_scripts
Validator::Site.connected do |task,supervisor,site|
  component = Validator.config['components']['detector_logic'].keys.first
  system(Validator.config['scripts']['activate_alarm'])
  site.log "Waiting for alarm", level: :test
  start_time = Time.now
  message, response = nil,nil
  expect do
    response = site.wait_for_alarm task, component: component, aCId: 'A0302',
      aSp: 'Issue', aS: 'Active', timeout: Validator.config['timeouts']['alarm']
  end.to_not raise_error, "Did not receive alarm"
  delay = Time.now - start_time
  site.log "alarm confirmed after #{delay.to_i}s", level: :test
  system(Validator.config['scripts']['deactivate_alarm'])
  alarm_time = Time.parse(response[:message].attributes["aTs"])
  expect(alarm_time).to be_within(1.minute).of Time.now.utc
  expect(response[:message].attributes['rvs']).to eq([{
    "n":"detector","v":"1"},
    {"n":"type","v":"loop"},
    {"n":"errormode","v":"on"},
    {"n":"manual","v":"True"},
    {"n":"logicerror","v":"always_off"}
  ])
ensure
  system(Validator.config['scripts']['deactivate_alarm'])
end
```
</details>




## Alarm can be acknowledged

Validata that an alarm can be acknowledged.

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
skip "Don't yet have a way to trigger alarms on the equipment"
require_scripts
Validator::Site.connected do |task,supervisor,site|
  component = Validator.config['components']['detector_logic'].keys.first
  system(Validator.config['scripts']['activate_alarm'])
  site.log "Waiting for alarm", level: :test
  start_time = Time.now
  message, response = nil,nil
  expect do
    response = site.wait_for_alarm task, component: component, aCId: 'A0302',
      aSp: 'Issue', aS: 'Active', timeout: Validator.config['timeouts']['alarm']
  end.to_not raise_error, "Did not receive alarm"
  alarm_code_id = 'A0302'
  message = site.send_alarm_acknowledgement Validator.config['main_component'], alarm_code_id
  delay = Time.now - start_time
  site.log "alarm confirmed after #{delay.to_i}s", level: :test
  expect do
    response = @site.wait_for_alarm_acknowledged_response message: message, component: Validator.config['main_component'], timeout: Validator.config['timeouts']['alarm']
  end.to_not raise_error
  expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
  expect(response).to be_a(RSMP::AlarmAcknowledgedResponse)
  expect(response.attributes['cId']).to eq(Validator.config['main_component'])
ensure 
  system(Validator.config['scripts']['deactivate_alarm'])
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
require_scripts
component = Validator.config['components']['detector_logic'].keys.first
Validator::Site.isolated do |task,supervisor,site|
end
# Activate alarm
system(Validator.config['scripts']['activate_alarm'])
Validator::Site.isolated do |task,supervisor,site|
  site = site
  log_confirmation "Waiting for alarm" do
    message, response = nil,nil
    expect do
      response = site.wait_for_alarm task, component: component, aCId: 'A0302',
        aSp: 'Issue', aS: 'Active', timeout: Validator.config['timeouts']['alarm']
    end.to_not raise_error, "Did not receive alarm"
  end
  system(Validator.config['scripts']['deactivate_alarm'])
  alarm_time = Time.parse(response[:message].attributes["aTs"])
  expect(alarm_time).to be_within(1.minute).of Time.now.utc
  expect(response[:message].attributes['rvs']).to eq([{
    "n":"detector","v":"1"},
    {"n":"type","v":"loop"},
    {"n":"errormode","v":"on"},
    {"n":"manual","v":"True"},
    {"n":"logicerror","v":"always_off"}
  ])
ensure
  system(Validator.config['scripts']['deactivate_alarm'])
end
```
</details>


