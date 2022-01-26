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
request_status_and_confirm "all-red status",
{ S0012: [:status,:intersection] }
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
request_status_and_confirm "control mode",
{ S0020: [:controlmode,:intersection] }
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
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  switch_dark_mode
  switch_normal_control
end
```
</details>




## Operational emergency stage is read with S0006

Verify status S0006 emergency stage

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "emergency stage status",
{ S0006: [:status,:emergencystage] }
```
</details>




## Operational fixed time activation should cause all groups to go to state A or B

Verify 
1. Verify connection
2. Send the control command to switch to fixed time= true
3. Wait for status = true
4. Send control command to switch "fixed time"= true
5. Wait for status = false

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  switch_fixed_time 'True'
  wait_for_status(@task,"Fixed time control active", [{'sCI'=>'S0009','n'=>'status','s'=>'True'}])
  wait_for_status(@task,"signalgroupstatus A or B", [{'sCI'=>'S0001','n'=>'signalgroupstatus','s'=>/^[AB]$/}])
  switch_fixed_time 'False'
end
```
</details>




## Operational fixed time control can be activated with M0007

1. Verify connection

2. Send the control command to switch to  fixed time= true
3. Wait for status = true
4. Send control command to switch "fixed time"= true
5. Wait for status = false

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
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
request_status_and_confirm "fixed time control status",
{ S0009: [:status,:intersection] }
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
request_status_and_confirm "isolated control status",
{ S0010: [:status,:intersection] }
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
request_status_and_confirm "manual control status",
{ S0008: [:status,:intersection] }
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
request_status_and_confirm "police key",
{ S0013: [:status] }
```
</details>




## Operational startup status is read with S0005

Verify status S0005 traffic controller starting

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "traffic controller starting (true/false)",
{ S0005: [:status] }
```
</details>




## Operational switched on is read with S0007

Verify status S0007 controller switched on (dark mode=off)

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "controller switch on (dark mode=off)",
{ S0007: [:status,:intersection] }
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
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  timeout =  10
  switch_yellow_flash
  wait_for_groups 'c', timeout: timeout      # c mean s yellow flash
  switch_normal_control
  wait_for_groups '[^c]', timeout: timeout   # not c, ie. not yellow flash
end
```
</details>




## Operational yellow flash can be activated with M0001

Verify that we can activate yellow flash

1. Given the site is connected
2. Send command to switch to yellow flash
3. Wait for yellow flash
4. Send command to switch to normal control
5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
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
request_status_and_confirm "yellow flash status",
{ S0011: [:status,:intersection] }
```
</details>


