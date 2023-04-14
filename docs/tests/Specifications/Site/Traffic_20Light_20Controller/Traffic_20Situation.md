---
layout: page
title: Traffic Situation
parmalink: traffic_light_controller_traffic_situation
has_children: false
has_toc: false
parent: Traffic Light Controller
grand_parent: Site
---

# Traffic Light Controller Traffic Situation
{: .no_toc}



### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Traffic situation is read with S0015

Verify status S0015 current traffic situation

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  if RSMP::Proxy.version_meets_requirement?( site.sxl_version, '>=1.1' )
    status_list = { S0015: [:status,:source] }
  else
    status_list = { S0015: [:status] }
  end
  request_status_and_confirm site, "current traffic situation", status_list
end
```
</details>




## Traffic situation is set with M0003

Verify that we change traffic situtation

1. Given the site is connected
2. Verify that there is a Validator.config['validator'] with a traffic situation
3. Send the control command to switch traffic situation for each traffic situation
4. Wait for status "Current traffic situatuon" = requested traffic situation

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
situations = Validator.config['items']['traffic_situations']
skip("No traffic situations configured") if situations.nil? || situations.empty?
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  situations.each { |traffic_situation| switch_traffic_situation traffic_situation.to_s }
ensure
  unset_traffic_situation
end
```
</details>




## Traffic situation list size is read with S0019

Verify status S0019 number of traffic situations

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  request_status_and_confirm site, "number of traffic situations",
    { S0019: [:number] }
end
```
</details>


