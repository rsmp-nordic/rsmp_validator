---
layout: page
title: Signal Group
parmalink: traffic_light_controller_signal_group
has_children: false
has_toc: false
parent: Traffic Light Controller
grand_parent: Site
---

# Traffic Light Controller Signal Group
{: .no_toc}



### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Signal group follow startup sequence after yellow flash

Verify that we can activate normal control after yellow flash mode is turned off

1. Given the site is connected and in yellow flash mode
2. When we activate normal control
3. All signal groups should go through e, f and g

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  verify_startup_sequence do
    switch_yellow_flash
    switch_normal_control
  end
  set_functional_position 'NormalControl'
end
```
</details>




## Signal group follows startup sequence after restart

Verify that groups follow startup sequence after a restart

1. Given the site is connected
2. And has just been restarted
3. Then all signal groups should follow the startup sequence

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  supervisor.ignore_errors RSMP::DisconnectError do
    verify_startup_sequence do
      set_restart
      site.wait_for_state :disconnected, timeout: Validator.config['timeouts']['shutdown']
      site.wait_for_state :ready, timeout: Validator.config['timeouts']['ready']
    end
  end
end
```
</details>




## Signal group is ordered to green with M0010

Validate that a signal group can be ordered to green using the M0010 command.

1. Verify connection
2. Send control command to start signalgrup, set_signal_start= true, include security_code
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  set_signal_start
end
```
</details>




## Signal group is ordered to red with M0011

1. Verify connection
2. Send control command to stop signalgrup, set_signal_start= false, include security_code
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  set_signal_stop
end
```
</details>




## Signal group list size is read with S0017

Verify status S0017 number of signal groups

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "number of signal groups",
{ S0017: [:number] }
```
</details>




## Signal group red/green predictions is read with S0025

Verify that time-of-green/time-of-red can be read with S0025.

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "time-of-green/time-of-red",
{ S0025: [
    :minToGEstimate,
    :maxToGEstimate,
    :likelyToGEstimate,
    :ToGConfidence,
    :minToREstimate,
    :maxToREstimate,
    :likelyToREstimate
] },
Validator.config['components']['signal_group'].keys.first
```
</details>




## Signal group series can be started/stopped with M0012

1. Verify connection
2. Send control command to start or stop a serie of signalgroups
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  set_signal_start_or_stop '5,4134,65;5,11'
end
```
</details>




## Signal group state is read with S0001

Verify that signal group status can be read with S0001.

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "signal group status",
{ S0001: [:signalgroupstatus, :cyclecounter, :basecyclecounter, :stage] }
```
</details>


