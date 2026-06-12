---
layout: page
title: Traffic Situations
parmalink: tlc_trafficsituations
has_children: false
has_toc: false
parent: Tlc
grand_parent: Site
---

# Traffic Situations
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Traffic Situations is read with S0015

Verify status S0015 current traffic situation

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is read with S0015' do
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    status_list = if RSMP::Proxy.version_meets_requirement?(site_proxy.sxl_version, '>=1.1')
                    { S0015: %i[status source] }
                  else
                    { S0015: [:status] }
                  end
    site_proxy.request_status_and_collect(status_list,
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Traffic Situations is set with M0003

Verify that we change traffic situation

1. Given the site_proxy is connected
2. Verify that there is a RSMP::Validator.get_config('validator') with a traffic situation
3. Send the control command to switch traffic situation for each traffic situation
4. Wait for status "Current traffic situation" = requested traffic situation

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is set with M0003' do
  skip 'requires sxl >= 1.0.7' unless RSMP::Validator.sxl_matches?('>=1.0.7')
  situations = RSMP::Validator.get_config('items', 'traffic_situations')
  skip('No traffic situations configured') if situations.nil? || situations.empty?
  timeout = RSMP::Validator.get_config('timeouts', 'command')
  with_site(:connected) do |site_proxy|
    situations.each do |traffic_situation|
      assert site_proxy.tlc.set_traffic_situation(traffic_situation.to_s, within: timeout)
    end
  ensure
    site_proxy.tlc.unset_traffic_situation(within: timeout)
  end
end
```
</details>


## Traffic Situations list size is read with S0019

Verify status S0019 number of traffic situations

1. Given the site_proxy is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'list size is read with S0019' do
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    site_proxy.request_status_and_collect({ S0019: [:number] },
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>
