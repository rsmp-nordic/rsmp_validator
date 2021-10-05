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

{{ site.base_url }}


### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Output forcing is read with S0030

Verify status S0030 forced output status

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "forced output status",
{ S0030: [:status] }
```
</details>




## Output forcing is set with M0020

1. Verify connection
2. Send control command to set force ounput
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
  force_output status, output, outputValue
end
```
</details>


