---
layout: page
title: Input
parmalink: traffic_light_controller_io_input
has_children: false
has_toc: false
parent: IO
grand_parent: Traffic Light Controller
---

# Traffic Light Controller IO Input
{: .no_toc}



### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Input forcing is read with S0029

Verify that we can read forced input status with S0029
1. Given the site is connected
2. When we read input with S0029
3. Then we should receive a valid response

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  request_status_and_confirm site, "forced input status",
    { S0029: [:status] }
end
```
</details>




## Input forcing is set with M0019

Verify that we can force input with M0019
1. Given the site is connected
2. And the input is forced off
2. When we force the input on
3. Then S0003 should show the input on

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  inputs = Validator.get_config('items','inputs')
  skip("No inputs configured") if inputs.nil? || inputs.empty?
  inputs.each do |input|
    force_input input: input, status: 'True', value: 'False'
    force_input input: input, status: 'True', value: 'True'
  ensure
    force_input input: input, status: 'False', validate: false
  end
end
```
</details>




## Input is activated with M0006

Verify that we can activate input with M0006
1. Given the site is connected
2. When we activate input with M0006
3. Then S0003 should show the input is active
4. When we deactivate input with M0006
5. Then S0003 should show the input is inactive

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  inputs = Validator.get_config('items','inputs')
  skip("No inputs configured") if inputs.nil? || inputs.empty?
  prepare task, site
  inputs.each { |input| switch_input input }
end
```
</details>




## Input is read with S0003

Verify that we can read input status with S0003
1. Given the site is connected
2. When we read input with S0029
3. Then we should receive a valid response

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  request_status_and_confirm site, "input status",
    { S0003: [:inputstatus] }
end
```
</details>




## Input is read with S0003 with extended input status

Verify that we can read input status with S0003, extendedinputstatus attribute
1. Given the site is connected
2. When we read input with S0029
3. Then we should receive a valid response

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  request_status_and_confirm site, "input status",
    { S0003: [:inputstatus,:extendedinputstatus] }
end
```
</details>




## Input sensitivity is set with M0021

Verify that input sensitivity can be set with M0021
1. Given the site is connected
2. When we set sensitivity with M0021
3. Then we receive a confirmation

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  status = '1-50'
  set_trigger_level status
end
```
</details>




## Input series is activated with M0013

Verify that we can acticate/deactivate a series of inputs with M0013
1. Given the site is connected
2. Send control command to set a serie of input
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  inputs = Validator.get_config('items','inputs')
  skip("No inputs configured") if inputs.nil? || inputs.empty?
  status = "1,3,12;5,5,10"
  set_series_of_inputs status
end
```
</details>


