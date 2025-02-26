---
layout: page
title: Traffic Data
parmalink: traffic_light_controller_traffic_data
has_children: false
has_toc: false
parent: Traffic Light Controller
grand_parent: Site
---

# Traffic Light Controller Traffic Data
{: .no_toc}



### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Traffic data classification for a single detector is read with S0204

Verify status S0204 traffic counting: classification

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  request_status_and_confirm site, "traffic counting: classification",
    { S0204: [
        :starttime,
        :P,
        :PS,
        :L,
        :LS,
        :B,
        :SP,
        :MC,
        :C,
        :F
    ] },
    Validator.get_config('components','detector_logic').keys.first
end
```
</details>




## Traffic data classification for all detectors is read with S0208

Verify status S0208 traffic counting: classification

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  request_status_and_confirm site, "traffic counting: classification",
    { S0208: [
        :start,
        :P,
        :PS,
        :L,
        :LS,
        :B,
        :SP,
        :MC,
        :C,
        :F
    ] }
end
```
</details>




## Traffic data number of vehicles for a single detector is read with S0201

Verify status S0201 traffic counting: number of vehicles

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  request_status_and_confirm site, "traffic counting: number of vehicles",
    { S0201: [:starttime,:vehicles] },
    Validator.get_config('components','detector_logic').keys.first
end
```
</details>




## Traffic data number of vehicles for all detectors is read with S0205

Verify status S0205 traffic counting: number of vehicles

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  request_status_and_confirm site, "traffic counting: number of vehicles",
    { S0205: [:start,:vehicles] }
end
```
</details>




## Traffic data occupancy for a single detector is read with S0203

Verify status S0203 traffic counting: occupancy

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  request_status_and_confirm site, "traffic counting: occupancy",
    { S0203: [:starttime,:occupancy] },
    Validator.get_config('components','detector_logic').keys.first
end
```
</details>




## Traffic data occupancy for all detectors is read with S0207

Verify status S0207 traffic counting: occupancy

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  result = wait_for_status task, "traffic counting: occupancy",
    { S0207: [:start,:occupancy] },
    update_rate: 60
  status = result[:collector].messages.first
  expect(status).to be_a(RSMP::StatusUpdate)
  occupancy_item = status.attribute("sS").find {|item| item["n"] == "occupancy" }
  expect(occupancy_item).to be_a(Hash)
  occupancies = occupancy_item["s"].split(",")
  occupancies.each do |occupancy|
    num = occupancy.to_i
    expect((-1..100).cover?(num)).to be_truthy, "Occupancy must be in the range -1..100, got #{num}"
  end
end
```
</details>




## Traffic data vehicle speed for a single detector is read with S0202

Verify status S0202 traffic counting: vehicle speed

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  request_status_and_confirm site, "traffic counting: vehicle speed",
    { S0202: [:starttime,:speed] },
    Validator.get_config('components','detector_logic').keys.first
end
```
</details>




## Traffic data vehicle speed for all detectors is read with S0206

Verify status S0206 traffic counting: vehicle speed

1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  request_status_and_confirm site, "traffic counting: vehicle speed",
    { S0206: [:start,:speed] }
end
```
</details>


