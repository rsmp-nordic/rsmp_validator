---
layout: page
title: Operational
parmalink: traffic_light_controller_operational
has_children: false
has_toc: false
parent: Traffic Light Controller
grand_parent: Site
---

# Traffic Light Controller Operational
{: .no_toc}



### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Operational all red can be read with S0012

Verify status S0012 all red

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  if RSMP::Proxy.version_meets_requirement?( site.sxl_version, '>=1.1' )
    status_list = { S0012: [:status,:intersection,:source] }
  else
    status_list = { S0012: [:status,:intersection] }
  end
  request_status_and_confirm site, "all-red status", status_list
end
```
</details>




## Operational control mode is read with S0020

Verify status S0020 control mode

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  request_status_and_confirm site, "control mode",
    { S0020: [:controlmode,:intersection] }
end
```
</details>




## Operational coordinated control is read with S0032

Verify status S0032 coordinated control

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  status_list = { S0032: [:status,:intersection,:source] }
  request_status_and_confirm site, "coordinated control status", status_list
end
```
</details>




## Operational dark mode can be activated with M0001

Verify that we can activate dark mode

1. Given the site is connected
2. Send the control command to switch todarkmode
3. Wait for status"Controller on" = false
4. Send command to switch to normal control
5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  prepare task, site
  switch_dark_mode
  switch_normal_control
end
```
</details>




## Operational fixed time control can be activated with M0007

Verify command M0007 fixed time control

1. Verify connection
2. Send command to switch to fixed time = true
3. Wait for status = true
4. Send command to switch to fixed time = false
5. Wait for status = false

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  prepare task, site
  switch_fixed_time 'True'
  switch_fixed_time 'False'
end
```
</details>




## Operational fixed time control is read with S0009

Verify status S0009 fixed time control

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  if RSMP::Proxy.version_meets_requirement?( site.sxl_version, '>=1.1' )
    status_list = { S0009: [:status,:intersection,:source] }
  else
    status_list = { S0009: [:status,:intersection] }
  end
  request_status_and_confirm site, "fixed time control status", status_list
end
```
</details>




## Operational isolated control is read with S0010

Verify status S0010 isolated control

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  if RSMP::Proxy.version_meets_requirement?( site.sxl_version, '>=1.1' )
    status_list = { S0010: [:status,:intersection,:source] }
  else
    status_list = { S0010: [:status,:intersection] }
  end
  request_status_and_confirm site, "isolated control status", status_list
end
```
</details>




## Operational manual control is read with S0008

Verify status S0008 manual control

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  if RSMP::Proxy.version_meets_requirement?( site.sxl_version, '>=1.1' )
    status_list = { S0008: [:status,:intersection,:source] }
  else
    status_list = { S0008: [:status,:intersection] }
  end
  request_status_and_confirm site, "manual control status", status_list
end
```
</details>




## Operational police key can be read with S0013

Verify status S0013 police key

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  request_status_and_confirm site, "police key",
    { S0013: [:status] }
end
```
</details>




## Operational startup status is read with S0005

Verify status S0005 traffic controller starting by intersection
statusByIntersection requires core >= 3.2, since it uses the array data type.

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  request_status_and_confirm site, "traffic controller starting (true/false)",
    { S0005: [:statusByIntersection] }
end
```
</details>




## Operational switched on is read with S0007

Verify status S0007 controller switched on, source attribute

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  status_list = { S0007: [:status,:intersection,:source] }
  request_status_and_confirm site, "controller switch on (dark mode=off)", status_list
end
```
</details>




## Operational yellow flash affects all signal groups

Verify that we can yellow flash causes all groups to go to state 'c'

1. Given the site is connected
2. Send the control command to switch to Yellow flash
3. Wait for all groups to go to group 'c'
4. Send command to switch to normal control
5. Wait for all groups to switch do something else that 'c'

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  prepare task, site
  timeout =  Validator.get_config('timeouts','yellow_flash')
  switch_yellow_flash
  wait_for_groups 'c', timeout: timeout      # c mean s yellow flash
  switch_normal_control
  wait_for_groups '[^c]', timeout: timeout   # not c, ie. not yellow flash
end
```
</details>




## Operational yellow flash be used with a timeout of one minute

Verify that we can activate yellow flash and after 1 minute goes back to NormalControl

1. Given the site is connected
2. Send the control command to switch to Normal Control, and wait for this
2. Send the control command to switch to Yellow flash
3. Wait for status Yellow flash
5. Wait for automatic revert to Normal Control

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  prepare task, site
  switch_normal_control
  minutes = 1
  switch_yellow_flash timeout_minutes: minutes
  wait_normal_control timeout: minutes*60 + Validator.get_config('timeouts','functional_position')
end
```
</details>




## Operational yellow flash can be activated with M0001

Verify that we can activate yellow flash

1. Given the site is connected
2. Send the control command to switch to Yellow flash
3. Wait for status Yellow flash
4. Send command to switch to normal control
5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  prepare task, site
  switch_yellow_flash
  switch_normal_control
end
```
</details>




## Operational yellow flash can be read with S0011

Verify status S0011 yellow flash

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  if RSMP::Proxy.version_meets_requirement?( site.sxl_version, '>=1.1' )
    status_list = { S0011: [:status,:intersection,:source] }
  else
    status_list = { S0011: [:status,:intersection] }
  end
  request_status_and_confirm site, "yellow flash status", status_list
end
```
</details>


