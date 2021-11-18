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
request_status_and_confirm "current traffic situation",
{ S0015: [:status] }
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
request_status_and_confirm "number of traffic situations",
{ S0019: [:number] }
```
</details>

