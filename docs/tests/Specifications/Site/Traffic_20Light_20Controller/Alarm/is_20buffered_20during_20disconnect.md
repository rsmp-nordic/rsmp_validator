---
layout: page
title: is buffered during disconnect
parent: Alarm
---

# Alarm is buffered during disconnect



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

