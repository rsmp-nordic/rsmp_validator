---
layout: page
title: Signal Plans
parmalink: tlc_signalplans
has_children: false
has_toc: false
parent: Tlc
grand_parent: Site
---

# Signal Plans
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Signal Plans config is read with S0098

Verify status S0098 configuration of traffic parameters

1. Given the site_proxy is connected
2. When we request the status
3. We should receive a status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'config is read with S0098' do
  with_site(:connected, sxl: '>=1.0.15') do |site_proxy|
    timeout = RSMP::Validator.get_config('timeouts', 'status_response')
    collector = site_proxy.request_status_and_collect(
      { S0098: %i[timestamp config version] },
      within: timeout
    )
    collector.ok!
    ss = collector.messages.last.attributes['sS']
    values = ss.to_h { |i| [i['n'], i['s']] }
    assert(!values['timestamp'].empty?, 'expected timestamp to not be empty')
    assert(!values['config'].empty?, 'expected config to not be empty')
    assert(!values['version'].empty?, 'expected version to not be empty')
  end
end
```
</details>


## Signal Plans currently active is read with S0014

Verify status S0014 current time plan

1. Given the site_proxy is connected
2. When we request the status
3. We should receive a status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'currently active is read with S0014' do
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    status_list = if RSMP::Proxy.version_meets_requirement?(site_proxy.sxl_version, '>=1.1')
                    { S0014: %i[status source] }
                  else
                    { S0014: [:status] }
                  end
    site_proxy.request_status_and_collect(status_list,
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Signal Plans currently active is set with M0002

Verify that we change time plan (signal program)
We try switching all programs configured

1. Given the site_proxy is connected
2. And there is a RSMP::Validator.get_config('validator') with a time plan
3. When we send the command
3. We should receive a confirmative command response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'currently active is set with M0002' do
  skip 'requires sxl >= 1.0.7' unless RSMP::Validator.sxl_matches?('>=1.0.7')
  plans = RSMP::Validator.get_config('items', 'plans')
  skip('No time plans configured') if plans.nil? || plans.empty?
  with_site(:connected) do |site_proxy|
    RSMP::Validator.get_config('secrets', 'security_codes', 2)
    plans.each do |plan|
      command_timeout = RSMP::Validator.get_config('timeouts', 'command')
      status_timeout = RSMP::Validator.get_config('timeouts', 'status_response')
      site_proxy.tlc.set_timeplan(plan, within: command_timeout)
      s0014_fields = if RSMP::Proxy.version_meets_requirement?(site_proxy.sxl_version, '>=1.1')
                       { S0014: %i[status source] }
                     else
                       { S0014: [:status] }
                     end
      collector = site_proxy.request_status_and_collect(
        s0014_fields,
        within: status_timeout
      )
      collector.ok!
      ss = collector.messages.last.attributes['sS']
      expect(ss.find { |i| i['n'] == 'status' }&.fetch('s').to_i).to eq(plan)
    end
  end
end
```
</details>


## Signal Plans cycle time is read with S0028

Verify status S0028 cycle time

1. Given the site_proxy is connected
2. When we request the status
3. We should receive a status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'cycle time is read with S0028' do
  with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
    site_proxy.request_status_and_collect({ S0028: [:status] },
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Signal Plans cycle time is set with M0018

Verify that cycle time can be changed with M0018

1. Given the site_proxy is connected
2. And we read cycle times
3. When we extend cycle time of curent plan with 5s
4. Then reading the cycle time should confirm the change
5. Finally when we revert cycle time to previous value
6. Then reading cycle time should confirm the reversion

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'cycle time is set with M0018' do
  with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
    with_cycle_time_extended(site_proxy) do
      log 'Cycle time extension confirmed'
    end
  end
end
```
</details>


## Signal Plans day table is read with S0027

Verify status S0027 time tables

1. Given the site_proxy is connected
2. When we request the status
3. We should receive a status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'day table is read with S0027' do
  with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
    site_proxy.request_status_and_collect({ S0027: [:status] },
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Signal Plans day table is set with M0017

Verify that we can set day table with M0017

1. Given the site_proxy is connected
2. When we send the command
3. We should receive a confirmative command response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'day table is set with M0017' do
  with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
    status = '12-1-12-59,1-0-23-12'
    timeout = RSMP::Validator.get_config('timeouts', 'command_response')
    site_proxy.tlc.set_day_table(status, within: timeout)
  end
end
```
</details>


## Signal Plans dynamic bands are read with S0023

Verify status S0023 command table

1. Given the site_proxy is connected
2. When we request the status
3. We should receive a status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'dynamic bands are read with S0023' do
  with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
    site_proxy.request_status_and_collect({ S0023: [:status] },
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Signal Plans dynamic bands are set with M0014

Verify that dynamic bands can the set with M0014

1. Given the site_proxy is connected
2. When we send the command
3. We should receive a confirmative command response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'dynamic bands are set with M0014' do
  with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
    plan = RSMP::Validator.get_config('items', 'plans').first
    status = '1-12'
    timeout = RSMP::Validator.get_config('timeouts', 'command_response')
    site_proxy.tlc.set_dynamic_bands(plan: plan, status: status, within: timeout)
  end
end
```
</details>


## Signal Plans dynamic bands values can be changed and read back

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'dynamic bands values can be changed and read back' do
  with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
    plan = RSMP::Validator.get_config('items', 'plans').first
    band = 3
    value = site_proxy.tlc.read_dynamic_band(plan: plan, band: band) || 0
    expect(value).to be_a(Integer)
    new_value = value + 1
    timeout = RSMP::Validator.get_config('timeouts', 'command_response')
    site_proxy.tlc.set_dynamic_bands(plan: plan, status: "#{band}-#{new_value}", within: timeout)
    expect(site_proxy.tlc.read_dynamic_band(plan: plan, band: band)).to eq(new_value)
    site_proxy.tlc.set_dynamic_bands(plan: plan, status: "#{band}-#{value}", within: timeout)
    expect(site_proxy.tlc.read_dynamic_band(plan: plan, band: band)).to eq(value)
  end
end
```
</details>


## Signal Plans list is read with S0022

Verify status S0022 list of time plans

1. Given the site_proxy is connected
2. When we request the status
3. We should receive a status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'list is read with S0022' do
  with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
    site_proxy.request_status_and_collect({ S0022: [:status] },
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Signal Plans list size is read with S0018

Verify status S0018 number of time plans
Deprecated from 1.2, use S0022 instead.

1. Given the site_proxy is connected
2. When we request the status
3. We should receive a status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'list size is read with S0018' do
  with_site(:connected, sxl: ['>=1.0.7', '<1.2']) do |site_proxy|
    site_proxy.request_status_and_collect({ S0018: [:number] },
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Signal Plans offset is read with S0024

Verify status S0024 offset time

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'offset is read with S0024' do
  with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
    site_proxy.request_status_and_collect({ S0024: [:status] },
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Signal Plans offset is set with M0015

1. Verify connection
2. Send control command to set dynamic_bands
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'offset is set with M0015' do
  with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
    plan = RSMP::Validator.get_config('items', 'plans').first
    offset = 99
    timeout = RSMP::Validator.get_config('timeouts', 'command_response')
    site_proxy.tlc.set_offset(plan: plan, offset: offset, within: timeout)
  end
end
```
</details>


## Signal Plans timeout for dynamic bands is set with M0023

Verify command M0023 timeout of dynamic bands

1. Given the site_proxy is connected
2. When we send command to set timeout
3. Then we should get a confirmation
2. When we send command to disable timeout
3. Then we should get a confirmation

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'timeout for dynamic bands is set with M0023' do
  with_site(:connected, sxl: '>=1.1') do |site_proxy|
    timeout = RSMP::Validator.get_config('timeouts', 'command_response')
    status = 10
    site_proxy.tlc.set_dynamic_bands_timeout(status, within: timeout)
    status = 0
    site_proxy.tlc.set_dynamic_bands_timeout(status, within: timeout)
  end
end
```
</details>


## Signal Plans version is read with S0097

Verify status S0097 version of traffic program

1. Given the site_proxy is connected
2. When we request the status
3. We should receive a status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'version is read with S0097' do
  with_site(:connected, sxl: '>=1.0.15') do |site_proxy|
    site_proxy.request_status_and_collect({ S0097: %i[timestamp checksum] },
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Signal Plans week table is read with S0026

Verify status S0026 week time table

1. Given the site_proxy is connected
2. When we request the status
3. We should receive a status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'week table is read with S0026' do
  with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
    site_proxy.request_status_and_collect({ S0026: [:status] },
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Signal Plans week table is set with M0016

Verify that we can set week table with M0016

1. Given the site_proxy is connected
2. When we send the command
3. We should receive a confirmative command response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'week table is set with M0016' do
  with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
    status = '0-1,6-2'
    timeout = RSMP::Validator.get_config('timeouts', 'command_response')
    site_proxy.tlc.set_week_table(status, within: timeout)
  end
end
```
</details>
