---
layout: page
title: Signal Priority
parmalink: tlc_signalpriority
has_children: false
has_toc: false
parent: Tlc
grand_parent: Site
---

# Signal Priority
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Signal Priority becomes completed when cancelled

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'becomes completed when cancelled' do
  with_site(:connected, core: '>=3.2', sxl: '>=1.1') do |site_proxy|
    timeout = Validator.get_config('timeouts', 'priority_completion')
    component = Validator.get_config('main_component')
    signal_group_id = Validator.get_config('components', 'signal_group').keys.first
    prio = Validator::Helpers::SignalPriority::RequestHelper.new(
      site_proxy,
      component: component,
      signal_group_id: signal_group_id,
      timeout: timeout,
      task: Async::Task.current
    )
    prio.run do
      log 'Before: Send unrelated signal priority request.'
      prio.request_unrelated
      log 'Send signal priority request, wait for reception.'
      prio.request
      log 'After: Send unrelated signal priority request.'
      prio.request_unrelated
      prio.expect :received
      log 'Signal priority request was received, wait for activation.'
      prio.expect :activated
      log 'Signal priority request was activated, now cancel it and wait for completion.'
      prio.cancel
      prio.expect :completed
      log 'Signal priority request was completed.'
    end
  end
end
```
</details>


## Signal Priority becomes stale if not cancelled

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'becomes stale if not cancelled' do
  with_site(:connected, core: '>=3.2', sxl: '>=1.1') do |site_proxy|
    timeout = Validator.get_config('timeouts', 'priority_completion')
    component = Validator.get_config('main_component')
    signal_group_id = Validator.get_config('components', 'signal_group').keys.first
    prio = Validator::Helpers::SignalPriority::RequestHelper.new(
      site_proxy,
      component: component,
      signal_group_id: signal_group_id,
      timeout: timeout,
      task: Async::Task.current
    )
    prio.run do
      log 'Before: Send unrelated signal priority request.'
      prio.request_unrelated
      log 'Send signal priority request, wait for reception.'
      prio.request
      log 'After: Send unrelated signal priority request.'
      prio.request_unrelated
      prio.expect :received
      log 'Signal priority request was received, wait for activation.'
      prio.expect :activated
      log 'Signal priority request was activated, wait for it to become stale.'
      # don't cancel request, it should then become stale by itself
      prio.expect :stale
      log 'Signal priority request became stale.'
    end
  end
end
```
</details>


## Signal Priority can be requested with M0022

Validate that a signal priority can be requested.

1. Given the site_proxy is connected
2. When we send a signal priority request
3. Then we should receive an acknowledgement

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'can be requested with M0022' do
  with_site(:connected, core: '>=3.2', sxl: '>=1.1') do |site_proxy|
    signal_group = Validator.get_config('components', 'signal_group').keys.first
    command_list = RSMP::CommandList.new(:M0022, :requestPriority,
                                         requestId: SecureRandom.uuid[0..3],
                                         signalGroupId: signal_group,
                                         type: 'new',
                                         level: 7,
                                         eta: 10,
                                         vehicleType: 'car').to_a
    log "Request signal priority for signal group #{signal_group}"
    timeout = Validator.get_config('timeouts', 'command_response')
    site_proxy.send_command_and_collect(command_list, within: timeout).ok!
  end
end
```
</details>


## Signal Priority status can be fetched with S0033

Validate that signal priority status can be requested.

1. Given the site_proxy is connected
2. When we request signal priority status
3. Then we should receive a status update

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'status can be fetched with S0033' do
  with_site(:connected, core: '>=3.2', sxl: '>=1.1') do |site_proxy|
    site_proxy.request_status_and_collect({ S0033: [:status] },
                                          within: Validator.get_config('timeouts', 'status_response')).ok!
  end
end
```
</details>


## Signal Priority status can be subscribed to with S0033

Validate that we can subscribe signal priority status

1. Given the site_proxy is connected
2. And we subscribe to signal priority status updates
4. Then we should receive an acknowledgement
5. And we should reive a status updates

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'status can be subscribed to with S0033' do
  with_site(:connected, core: '>=3.2', sxl: '>=1.1') do |site_proxy|
    status_list = [{ 'sCI' => 'S0033', 'n' => 'status', 'uRt' => '0' }]
    status_list.map! { |item| item.merge!('sOc' => true) } if site_proxy.tlc.use_soc?
    wait_for_status(site_proxy, 'signal priority status', status_list)
  end
end
```
</details>
