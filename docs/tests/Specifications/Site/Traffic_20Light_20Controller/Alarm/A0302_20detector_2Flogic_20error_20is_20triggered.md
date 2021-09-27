---
layout: page
title: A0302 detector/logic error is triggered
parent: Alarm
---

# Alarm A0302 detector/logic error is triggered



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

