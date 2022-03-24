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
request_status_and_confirm "detector logic forcing",
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
  Validator.config['components']['detector_logic'].keys.each_with_index do |component, indx|
    force_detector_logic component, mode:'True'
    Validator.config['main_component'] = Validator.config['main_component']
    wait_for_status(@task,
      "detector logic #{component} to be True",
      [{'sCI'=>'S0002','n'=>'detectorlogicstatus','s'=>/^.{#{indx}}1/}]
    )
    
    force_detector_logic component, mode:'False'
    Validator.config['main_component'] = Validator.config['main_component']
    wait_for_status(@task,
      "detector logic #{component} to be False",
      [{'sCI'=>'S0002','n'=>'detectorlogicstatus','s'=>/^.{#{indx}}0/}]
    )
  end
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


