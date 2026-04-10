---
layout: page
title: Detector Logic
parmalink: detector_logic
has_children: false
has_toc: false
parent: Site::Tlc::DetectorLogics
grand_parent: Test Suite
---

# Detector Logic
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Detector logic forcing is read with S0021

Verify status S0021 manually set detector logic

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'forcing is read with S0021' do
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    request_status_and_confirm site_proxy, 'detector logic forcing',
                               { S0021: [:detectorlogics] }
  end
end
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
it 'forcing is set with M0008' do
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    Validator.get_config('components', 'detector_logic').keys.each_with_index do |component, indx|
      site_proxy.force_detector_logic(component, status: 'True', mode: 'True')
      wait_for_status(
        site_proxy,
        "detector logic #{component} to be True",
        [{ 'sCI' => 'S0002', 'n' => 'detectorlogicstatus', 's' => /^.{#{indx}}1/ }]
      )
      site_proxy.force_detector_logic(component, status: 'True', mode: 'False')
      wait_for_status(
        site_proxy,
        "detector logic #{component} to be False",
        [{ 'sCI' => 'S0002', 'n' => 'detectorlogicstatus', 's' => /^.{#{indx}}0/ }]
      )
    end
  end
end
```
</details>


## Detector logic list size is read with S0016

Verify status S0016 number of detector logics

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'list size is read with S0016' do
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    request_status_and_confirm site_proxy, 'number of detector logics',
                               { S0016: [:number] }
  end
end
```
</details>


## Detector logic sensitivity is read with S0031

Verify status S0031 trigger level sensitivity for loop detector

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'sensitivity is read with S0031' do
  with_site(:connected, sxl: '>=1.0.15') do |site_proxy|
    request_status_and_confirm site_proxy, 'loop detector sensitivity',
                               { S0031: [:status] }
  end
end
```
</details>


## Detector logic status is read with S0002

Verify status S0002 detector logic status

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'status is read with S0002' do
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    request_status_and_confirm site_proxy, 'detector logic status',
                               { S0002: [:detectorlogicstatus] }
  end
end
```
</details>
