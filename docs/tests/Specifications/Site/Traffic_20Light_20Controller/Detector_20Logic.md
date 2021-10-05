---
layout: page
title: Detector Logic
parmalink: traffic_light_controller_detector_logic
has_children: false
has_toc: false
parent: Traffic Light Controller
grand_parent: Site
---

# Traffic Light Controller Detector Logic
{: .no_toc}

{{ site.base_url }}


### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Detector logic forcing is read with S0021

Verify status S0021 manually set detector logic

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "manually set detector logics",
{ S0021: [:detectorlogics] }
```
</details>




## Detector logic forcing is set with M0008

1. Verify connection
2. Send control command to switch detector_logic= true
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  switch_detector_logic
end
```
</details>




## Detector logic list size is read with S0016

Verify status S0016 number of detector logics

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "number of detector logics",
{ S0016: [:number] }
```
</details>




## Detector logic sensitivity is set with S0031

Verify status S0031 trigger level sensitivity for loop detector

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "loop detector sensitivity",
{ S0031: [:status] }
```
</details>




## Detector logic status is read with S0002

Verify status S0002 detector logic status

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
request_status_and_confirm "detector logic status",
{ S0002: [:detectorlogicstatus] }
```
</details>


