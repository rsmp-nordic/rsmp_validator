---
layout: page
title: Output
parmalink: tlc_output
has_children: false
has_toc: false
parent: Tlc
grand_parent: Site
---

# Output
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Output forcing is read with S0030

Verify that forced output status can be read with S0030
1. Given the site is connected
2. Request status
3. Expect status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'forcing is read with S0030' do
  with_site(:connected, sxl: '>=1.0.15') do |site_proxy|
    site_proxy.request_status_and_collect({ S0030: [:status] },
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Output forcing is set with M0020

Verify that output can be forced with M0020
1. Given the site is connected
2. When we force output with M0020
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'forcing is set with M0020' do
  with_site(:connected, sxl: '>=1.0.15') do |site_proxy|
    outputs = RSMP::Validator.get_config('items', 'outputs')
    skip('No outputs configured') if outputs.nil? || outputs.empty?
    timeout = RSMP::Validator.get_config('timeouts', 'command_response')
    outputs.each do |output|
      site_proxy.tlc.force_output(output: output, status: 'True', value: 'True', within: timeout)
      site_proxy.tlc.force_output(output: output, status: 'True', value: 'False', within: timeout)
    ensure
      site_proxy.tlc.force_output(output: output, status: 'False', value: 'True', within: timeout)
    end
  end
end
```
</details>


## Output is read with S0004

Verify that  output status can be read with S0004
1. Given the site is connected
2. When we subscribe to S0004
3. We should receive a status updated
4. And the outputstatus attribute should be a digit string

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is read with S0004' do
  with_site(:connected, sxl: ['>=1.2']) do |site_proxy|
    site_proxy.request_status_and_collect({ S0004: [:outputstatus] },
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Output is read with S0004 with extended output status

Verify that  output status can be read with S0004, extended output status
1. Given the site is connected
2. When we subscribe to S0004
3. We should receive a status updated
4. And the outputstatus attribute should be a digit string

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is read with S0004 with extended output status' do
  with_site(:connected, sxl: ['>=1.0.7', '<1.2']) do |site_proxy|
    site_proxy.request_status_and_collect(
      { S0004: %i[outputstatus extendedoutputstatus] },
      within: RSMP::Validator.get_config('timeouts', 'status_response')
    ).ok!
  end
end
```
</details>
