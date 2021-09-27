---
layout: page
title: is acknowledged
parent: Alarm
---

# Alarm is acknowledged



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

