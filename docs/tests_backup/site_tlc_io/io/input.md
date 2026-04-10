---
layout: page
title: Input
parmalink: io_input
has_children: false
has_toc: false
parent: IO
grand_parent: Site::Tlc::Io
---

# IO Input
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
    request_status_and_confirm site, 'forced input status',
                               { S0029: [:status] }
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
    inputs = Validator.get_config('items', 'inputs')
    skip('No inputs configured') if inputs.nil? || inputs.empty?
    inputs.each do |input|
      site.force_input(input: input, status: 'True', value: 'False')
      site.force_input(input: input, status: 'True', value: 'True')
    ensure
      site.force_input(input: input, status: 'False', value: 'True')
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
  with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
    inputs = Validator.get_config('items', 'inputs')
    skip('No inputs configured') if inputs.nil? || inputs.empty?
    inputs.each { |input| switch_input(site, input) }
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
    request_status_and_confirm site, 'input status',
                               { S0003: [:inputstatus] }
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
    request_status_and_confirm site, 'input status',
                               { S0003: %i[inputstatus extendedinputstatus] }
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
    status = '1-50'
    site.set_trigger_level(status)
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
    inputs = Validator.get_config('items', 'inputs')
    skip('No inputs configured') if inputs.nil? || inputs.empty?
    status = '1,3,12;5,5,10'
    site.set_inputs(status)
  end
end
```
</details>
