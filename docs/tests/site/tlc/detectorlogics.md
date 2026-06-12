---
layout: page
title: Detector Logics
parmalink: tlc_detectorlogics
has_children: false
has_toc: false
parent: Tlc
grand_parent: Site
---

# Detector Logics
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Detector Logics forcing is read with S0021

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
    site_proxy.request_status_and_collect({ S0021: [:detectorlogics] },
                                          within: Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Detector Logics forcing is set with M0008

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
      timeout = Validator.get_config('timeouts', 'command_response')
      site_proxy.tlc.force_detector_logic(component, status: 'True', mode: 'True', within: timeout)
      wait_for_status(
        site_proxy,
        "detector logic #{component} to be True",
        [{ 'sCI' => 'S0002', 'n' => 'detectorlogicstatus', 's' => /^.{#{indx}}1/ }]
      )
      site_proxy.tlc.force_detector_logic(component, status: 'True', mode: 'False', within: timeout)
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


## Detector Logics list size is read with S0016

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
    site_proxy.request_status_and_collect({ S0016: [:number] },
                                          within: Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Detector Logics sensitivity is read with S0031

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
    site_proxy.request_status_and_collect({ S0031: [:status] },
                                          within: Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Detector Logics status is read with S0002

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
    site_proxy.request_status_and_collect({ S0002: [:detectorlogicstatus] },
                                          within: Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>
