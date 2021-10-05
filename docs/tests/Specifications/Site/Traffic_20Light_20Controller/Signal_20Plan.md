---
layout: page
title: Signal Plan
parmalink: traffic_light_controller_signal_plan
has_children: false
has_toc: false
parent: Traffic Light Controller
grand_parent: Site
---

# Traffic Light Controller Signal Plan
{: .no_toc}

site.baseurl: [{{ site.baseurl }}]



### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Signal plan currently active is read with S0014

Verify status S0014 current time plan

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "current time plan",
{ S0014: [:status] }
```
</details>




## Signal plan currently active is set with M0002

Verify that we change time plan (signal program)
We try switching all programs configured

1. Given the site is connected
2. Verify that there is a Validator.config['validator'] with a time plan
3. Send command to switch time plan
4. Wait for status "Current timeplan" = requested time plan

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
plans = Validator.config['items']['plans']
skip("No time plans configured") if plans.nil? || plans.empty?
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  plans.each { |plan| switch_plan plan }
end
```
</details>




## Signal plan cycle time is read with S0028

Verify status S0028 cycle time

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "cycle time",
{ S0028: [:status] }
```
</details>




## Signal plan cycle time is set with M0018

1. Verify connection
2. Send control command to set cycle time
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  status = 5
  plan = 0
  prepare task, site
  set_cycle_time status, plan
end
```
</details>




## Signal plan day table is read with S0027

Verify status S0027 time tables

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "command table",
{ S0027: [:status] }
```
</details>




## Signal plan day table is set with M0017

1. Verify connection
2. Send control command to set time_table
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  status = "12-1-12-59,1-0-23-12"
  prepare task, site
  set_time_table status
end
```
</details>




## Signal plan dynamic bands are read with S0023

Verify status S0023 command table

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "command table",
{ S0023: [:status] }
```
</details>




## Signal plan dynamic bands are set with M0014

1. Verify connection
2. Send control command to set dynamic_bands
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  plan = "1"
  status = "10,10"
  prepare task, site
  set_dynamic_bands status, plan
end
```
</details>




## Signal plan list is read with S0022

Verify status S0022 list of time plans

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "list of time plans",
{ S0022: [:status] }
```
</details>




## Signal plan list size is read with S0018

Verify status S0018 number of time plans

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "number of time plans",
{ S0018: [:number] }
```
</details>




## Signal plan offset is read with S0024

Verify status S0024 offset time

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "offset time",
{ S0024: [:status] }
```
</details>




## Signal plan offset is set with M0015

1. Verify connection
2. Send control command to set dynamic_bands
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  plan = 1
  status = 255
  prepare task, site
  set_offset status, plan
end
```
</details>




## Signal plan version is read with S0097

Verify status S0097 version of traffic program

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "version of traffic program",
{ S0097: [:timestamp,:checksum] }
```
</details>




## Signal plan week table is read with S0026

Verify status S0026 week time table

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "week time table",
{ S0026: [:status] }
```
</details>




## Signal plan week table is set with M0016

1. Verify connection
2. Send control command to set  week_table
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  status = "0-1,6-2"
  prepare task, site
  set_week_table status
end
```
</details>


