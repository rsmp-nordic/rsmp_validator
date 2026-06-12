---
layout: page
title: Signal Groups
parmalink: tlc_signalgroups
has_children: false
has_toc: false
parent: Tlc
grand_parent: Site
---

# Signal Groups
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Signal Groups follow startup sequence after yellow flash

Verify that we can activate normal control after yellow flash mode is turned off

1. Given the site_proxy is connected and in yellow flash mode
2. When we activate normal control
3. All signal groups should go through e, f and g

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'follow startup sequence after yellow flash' do
  skip 'requires sxl >= 1.0.7' unless RSMP::Validator.sxl_matches?('>=1.0.7')
  with_site(:connected) do |site_proxy|
    verify_startup_sequence(site_proxy) do
      timeout = RSMP::Validator.get_config('timeouts', 'yellow_flash')
      site_proxy.tlc.set_functional_position('YellowFlash', within: timeout)
      command_timeout = RSMP::Validator.get_config('timeouts', 'command_response')
      site_proxy.tlc.set_functional_position('NormalControl', within: command_timeout)
    end
    command_timeout ||= RSMP::Validator.get_config('timeouts', 'command_response')
    site_proxy.tlc.set_functional_position('NormalControl', within: command_timeout)
  end
end
```
</details>


## Signal Groups is ordered to green with M0010

Validate that a signal group can be ordered to green using the M0010 command.

1. Verify connection
2. Send control command to start signalgrup, set_signal_start= true, include security_code
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is ordered to green with M0010' do
  with_site(:connected, sxl: '>=1.0.8') do |site_proxy|
    component = RSMP::Validator.get_config('components', 'signal_group').keys[0]
    timeout = RSMP::Validator.get_config('timeouts', 'command_response')
    site_proxy.tlc.order_signal_start(component, within: timeout)
  end
end
```
</details>


## Signal Groups is ordered to red with M0011

1. Verify connection
2. Send control command to stop signalgrup, set_signal_start= false, include security_code
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is ordered to red with M0011' do
  with_site(:connected, sxl: '>=1.0.8') do |site_proxy|
    component = RSMP::Validator.get_config('components', 'signal_group').keys[0]
    timeout = RSMP::Validator.get_config('timeouts', 'command_response')
    site_proxy.tlc.order_signal_stop(component, within: timeout)
  end
end
```
</details>


## Signal Groups list size is read with S0017

Verify status S0017 number of signal groups

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'list size is read with S0017' do
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    site_proxy.request_status_and_collect({ S0017: [:number] },
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Signal Groups red/green predictions is read with S0025

Verify that time-of-green/time-of-red can be read with S0025.

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'red/green predictions is read with S0025' do
  with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
    component = RSMP::Validator.get_config('components', 'signal_group').keys.first
    site_proxy.request_status_and_collect(
      { S0025: %i[
        minToGEstimate
        maxToGEstimate
        likelyToGEstimate
        ToGConfidence
        minToREstimate
        maxToREstimate
        likelyToREstimate
      ] },
      component: component,
      within: RSMP::Validator.get_config('timeouts', 'status_response')
    ).ok!
  end
end
```
</details>


## Signal Groups state is read with S0001

Verify that signal group status can be read with S0001.

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'state is read with S0001' do
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    site_proxy.request_status_and_collect(
      { S0001: %i[signalgroupstatus cyclecounter basecyclecounter stage] },
      within: RSMP::Validator.get_config('timeouts', 'status_response')
    ).ok!
  end
end
```
</details>
