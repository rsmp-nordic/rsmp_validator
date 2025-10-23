---
layout: page
title: Output
parmalink: traffic_light_controller_io_output
has_children: false
has_toc: false
parent: IO
grand_parent: Traffic Light Controller
---

# Traffic Light Controller IO Output
{: .no_toc}



### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Output forcing is read with S0030

Verify that forced output status can be read with S0030
1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  prepare task, site
  request_status_and_confirm site, "forced output status",
    { S0030: [:status] }
end
```
</details>




## Output forcing is set with M0020

Verify that output can be forced with M0020
1. Given the site is connected
2. When we force output with M0020
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
   prepare task, site
   outputs = Validator.get_config('items','outputs')
   skip("No outputs configured") if outputs.nil? || outputs.empty?
   outputs.each do |output|
     force_output output: output, status:'True', value:'True'
     force_output output: output, status:'True', value:'False'
   ensure
     force_output output: output, status:'False', validate: false
   end
end
```
</details>




## Output is read with S0004

Verify that  output status can be read with S0004
1. Given the site is connected
2. When we subscribe to S0004
3. We should receive a status updated
4. And the outputstatus attribute should be a digit string

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  prepare task, site
  request_status_and_confirm site, "output status",
    { S0004: [:outputstatus] }
end
```
</details>


