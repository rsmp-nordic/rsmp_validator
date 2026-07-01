---
layout: page
title: Traffic Data
parmalink: tlc_trafficdata
has_children: false
has_toc: false
parent: Tlc
grand_parent: Site
---

# Traffic Data
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Traffic Data classification for a single detector is read with S0204

Verify status S0204 traffic counting: classification

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'classification for a single detector is read with S0204' do
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    component = RSMP::Validator.get_config('components', 'detector_logic').keys.first
    site_proxy.request_status_and_collect(
      { S0204: %i[
        starttime
        P
        PS
        L
        LS
        B
        SP
        MC
        C
        F
      ] },
      component: component,
      within: RSMP::Validator.get_config('timeouts', 'status_response')
    ).ok!
  end
end
```
</details>


## Traffic Data classification for all detectors is read with S0208

Verify status S0208 traffic counting: classification

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'classification for all detectors is read with S0208' do
  with_site(:connected, sxl: '>=1.0.14') do |site_proxy|
    site_proxy.request_status_and_collect(
      { S0208: %i[
        start
        P
        PS
        L
        LS
        B
        SP
        MC
        C
        F
      ] },
      within: RSMP::Validator.get_config('timeouts', 'status_response')
    ).ok!
  end
end
```
</details>


## Traffic Data number of vehicles for a single detector is read with S0201

Verify status S0201 traffic counting: number of vehicles

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'number of vehicles for a single detector is read with S0201' do
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    component = RSMP::Validator.get_config('components', 'detector_logic').keys.first
    site_proxy.request_status_and_collect(
      { S0201: %i[starttime vehicles] },
      component: component,
      within: RSMP::Validator.get_config('timeouts', 'status_response')
    ).ok!
  end
end
```
</details>


## Traffic Data number of vehicles for all detectors is read with S0205

Verify status S0205 traffic counting: number of vehicles

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'number of vehicles for all detectors is read with S0205' do
  with_site(:connected, sxl: '>=1.0.14') do |site_proxy|
    site_proxy.request_status_and_collect({ S0205: %i[start vehicles] },
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Traffic Data occupancy for a single detector is read with S0203

Verify status S0203 traffic counting: occupancy

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'occupancy for a single detector is read with S0203' do
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    component = RSMP::Validator.get_config('components', 'detector_logic').keys.first
    site_proxy.request_status_and_collect(
      { S0203: %i[starttime occupancy] },
      component: component,
      within: RSMP::Validator.get_config('timeouts', 'status_response')
    ).ok!
  end
end
```
</details>


## Traffic Data occupancy for all detectors is read with S0207

Verify status S0207 traffic counting: occupancy

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'occupancy for all detectors is read with S0207' do
  with_site(:connected, sxl: '>=1.0.14') do |site_proxy|
    result = wait_for_status(site_proxy, 'traffic counting: occupancy',
                             { S0207: %i[start occupancy] },
                             update_rate: 60)
    occupancies = result.matcher_got_hash.dig('S0207', 'occupancy')
    start = result.matcher_got_hash.dig('S0207', 'start')
    expect(start).to be_a(String)
    occupancy_values = if RSMP::Validator.sxl_matches?('<1.1')
                         expect(occupancies).to be_a(String)
                         occupancies.split(',').map do |occupancy|
                           assert(occupancy.match?(/\A-?\d+\z/), "Occupancy must be an Integer, got #{occupancy}")
                           occupancy.to_i
                         end
                       else
                         expect(occupancies).to be_a(Array)
                         occupancies
                       end
    occupancy_values.each do |occupancy|
      assert(occupancy.is_a?(Integer), "Occupancy must be an Integer, got #{occupancy.class}")
      assert((-1..100).cover?(occupancy), "Occupancy must be in the range -1..100, got #{occupancy}")
    end
  end
end
```
</details>


## Traffic Data vehicle speed for a single detector is read with S0202

Verify status S0202 traffic counting: vehicle speed

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'vehicle speed for a single detector is read with S0202' do
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    component = RSMP::Validator.get_config('components', 'detector_logic').keys.first
    site_proxy.request_status_and_collect(
      { S0202: %i[starttime speed] },
      component: component,
      within: RSMP::Validator.get_config('timeouts', 'status_response')
    ).ok!
  end
end
```
</details>


## Traffic Data vehicle speed for all detectors is read with S0206

Verify status S0206 traffic counting: vehicle speed

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'vehicle speed for all detectors is read with S0206' do
  with_site(:connected, sxl: '>=1.0.14') do |site_proxy|
    site_proxy.request_status_and_collect({ S0206: %i[start speed] },
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>
