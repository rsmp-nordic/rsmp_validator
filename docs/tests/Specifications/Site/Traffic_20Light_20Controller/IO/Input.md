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

{{ site.base_url }}


### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Input forcing is read with S0029

Verify status S0029 forced input status

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "forced input status",
{ S0029: [:status] }
```
</details>




## Input forcing is set with M0019

1. Verify connection
2. Send control command to set force input
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  status = 'False'
  input = 1
  inputValue = 'True'
  prepare task, site
  force_input status, input, inputValue
end
```
</details>




## Input is activated with M0006

1. Verify connection
2. Verify that there is a Validator.config['validator'] with a input
3. Send control command to switch input
4. Wait for status "input" = requested

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
inputs = Validator.config['items']['inputs']
skip("No inputs configured") if inputs.nil? || inputs.empty?
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  inputs.each { |input| switch_input input }
end
```
</details>




## Input sensitivity is set with M0021

1. Verify connection
2. Send control command to set trigger level
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  status = 'False'
  output = 1
  outputValue = 'True'
  prepare task, site
  set_trigger_level status
end
```
</details>




## Input series is activated with M0013

1. Verify connection
2. Send control command to set a serie of input
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  status = "5,4134,65;511"
  prepare task, site
  set_series_of_inputs status
end
```
</details>


