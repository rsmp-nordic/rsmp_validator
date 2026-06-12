---
layout: page
title: Alarm
parmalink: tlc_alarm
has_children: false
has_toc: false
parent: Tlc
grand_parent: Site
---

# Alarm
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Alarm can acknowledge A0302

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'can acknowledge A0302' do
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    alarm_code_id = 'A0302' # what alarm to expect
    timeout = RSMP::Validator.get_config('timeouts', 'alarm')
    log "Activating alarm #{alarm_code_id}"
    with_alarm_activated(site_proxy, alarm_code_id) do |alarm, component_id| # raise alarm, by activating input
      log "Alarm #{alarm_code_id} is now active on component #{component_id}"
      # verify timestamp
      alarm_time = Time.parse(alarm.attributes['aTs'])
      expect(alarm_time).to be_within(1.minute).of(Time.now.utc)
      # verify that the alarm is not acknowledged when initially raised
      ack_message = "Alarm should not be acknowledged when raised, got: #{alarm.attributes['ack']}"
      assert(alarm.attributes['ack'].match?(/notAcknowledged/i), ack_message)
      log "Verified alarm #{alarm_code_id} is correctly not acknowledged when raised"
      # test acknowledge and confirm
      log "Acknowledge alarm #{alarm_code_id}"
      collect_task = Async::Task.current.async do
        RSMP::AlarmCollector.new(site_proxy,
                                 num: 1,
                                 matcher: {
                                   'aCId' => alarm_code_id,
                                   'aSp' => /Acknowledge/i,
                                   'ack' => /Acknowledged/i,
                                   'aS' => /Active/i
                                 },
                                 timeout: timeout).collect!
      end
      site_proxy.send_message RSMP::AlarmAcknowledge.new(
        'cId' => component_id,
        'aTs' => site_proxy.clock.to_s,
        'aCId' => alarm_code_id
      )
      messages = collect_task.wait
      expect(messages).to be_a(Array)
      expect(messages.first).to be_a(RSMP::Alarm)
    end
  end
end
```
</details>


## Alarm can suspende and resume A0302

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'can suspende and resume A0302' do
  with_site(:connected) do |site_proxy|
    alarm_code_id = 'A0302'
    _, component_id = find_alarm_programming(alarm_code_id)
    # first resume alarm to make sure something happens when we suspend
    site_proxy.resume_alarm Async::Task.current, c_id: component_id, a_c_id: alarm_code_id, collect: false
    begin
      # suspend alarm
      _, response = site_proxy.suspend_alarm Async::Task.current, c_id: component_id, a_c_id: alarm_code_id,
                                                                  collect: true
      expect(response).to be_a(RSMP::AlarmSuspended)
      # resume alarm
      _, response = site_proxy.resume_alarm Async::Task.current, c_id: component_id, a_c_id: alarm_code_id,
                                                                 collect: true
      expect(response).to be_a(RSMP::AlarmResumed)
    ensure
      # always end with resuming alarm
      site_proxy.resume_alarm Async::Task.current, c_id: component_id, a_c_id: alarm_code_id, collect: false
    end
  end
end
```
</details>


## Alarm raises A0302 when input is activated

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'raises A0302 when input is activated' do
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    alarm_code_id = 'A0302'
    def verify_timestamp(alarm, duration = 1.minute)
      alarm_time = Time.parse(alarm.attributes['aTs'])
      expect(alarm_time).to be_within(duration).of(Time.now.utc)
    end
    # Raise alarm by activating input
    deactivated, component_id = with_alarm_activated(site_proxy, alarm_code_id) do |alarm, component_id|
      verify_timestamp alarm
      log "Alarm #{alarm_code_id} is now Active on component #{component_id}"
    end
    verify_timestamp deactivated
    log "Alarm #{alarm_code_id} is now Inactive on component #{component_id}"
  end
end
```
</details>
