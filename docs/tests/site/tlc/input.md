---
layout: page
title: Input
parmalink: tlc_input
has_children: false
has_toc: false
parent: Tlc
grand_parent: Site
---

# Input
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Input forcing is read with S0029

Verify that we can read forced input status with S0029
1. Given the site is connected
2. When we read input with S0029
3. Then we should receive a valid response

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'forcing is read with S0029' do
  with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
    site_proxy.request_status_and_collect({ S0029: [:status] },
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Input forcing is set with M0019

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'forcing is set with M0019' do
  with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
    inputs = RSMP::Validator.get_config('items', 'inputs')
    skip('No inputs configured') if inputs.nil? || inputs.empty?
    inputs.each do |input|
      timeout = RSMP::Validator.get_config('timeouts', 'command')
      site_proxy.tlc.force_input(input: input, status: 'True', value: 'False', within: timeout)
      site_proxy.tlc.force_input(input: input, status: 'True', value: 'True', within: timeout)
    ensure
      site_proxy.tlc.force_input(input: input, status: 'False', value: 'True', within: timeout)
    end
  end
end
```
</details>


## Input is activated with M0006

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is activated with M0006' do
  inputs = RSMP::Validator.get_config('items', 'inputs')
  skip('No inputs configured') if inputs.nil? || inputs.empty?
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    timeout = RSMP::Validator.get_config('timeouts', 'command_response')
    inputs.each { |input| switch_input(site_proxy, input, within: timeout) }
  end
end
```
</details>


## Input is read with S0003

Verify that we can read input status with S0003
1. Given the site is connected
2. When we read input with S0029
3. Then we should receive a valid response

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is read with S0003' do
  with_site(:connected, sxl: '>=1.2') do |site_proxy|
    site_proxy.request_status_and_collect({ S0003: [:inputstatus] },
                                          within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Input is read with S0003 with extended input status

Verify that we can read input status with S0003, extendedinputstatus attribute
1. Given the site is connected
2. When we read input with S0029
3. Then we should receive a valid response

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is read with S0003 with extended input status' do
  with_site(:connected, sxl: '<1.2') do |site_proxy|
    site_proxy.request_status_and_collect(
      { S0003: %i[inputstatus extendedinputstatus] },
      within: RSMP::Validator.get_config('timeouts', 'status_response')
    ).ok!
  end
end
```
</details>


## Input sensitivity is set with M0021

Verify that input sensitivity can be set with M0021
1. Given the site is connected
2. When we set sensitivity with M0021
3. Then we receive a confirmation

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'sensitivity is set with M0021' do
  with_site(:connected, sxl: '>=1.0.15') do |site_proxy|
    timeout = RSMP::Validator.get_config('timeouts', 'command_response')
    status = '1-50'
    site_proxy.tlc.set_trigger_level(status, within: timeout)
  end
end
```
</details>


## Input series is activated with M0013

Verify that we can acticate/deactivate a series of inputs with M0013
1. Given the site is connected
2. Send control command to set a serie of input
3. Wait for status = true

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'series is activated with M0013' do
  with_site(:connected, sxl: '>=1.0.8') do |site_proxy|
    inputs = RSMP::Validator.get_config('items', 'inputs')
    skip('No inputs configured') if inputs.nil? || inputs.empty?
    status = '1,3,12;5,5,10'
    timeout = RSMP::Validator.get_config('timeouts', 'command')
    site_proxy.tlc.set_inputs(status, within: timeout)
  end
end
```
</details>
