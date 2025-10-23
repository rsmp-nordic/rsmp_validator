---
layout: page
title: Signal Priority
parmalink: traffic_light_controller_signal_priority
has_children: false
has_toc: false
parent: Traffic Light Controller
grand_parent: Site
---

# Traffic Light Controller Signal Priority
{: .no_toc}



### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Signal priority becomes completed when cancelled

Validate that a signal priority completes when we cancel it.

1. Given the site is connected
2. And we subscribe to signal priority status
3. When we send a signal priority request
4. Then the request state should become 'received'
5. Then the request state should become 'activated'
6. When we cancel the request
7. Then the state should become 'completed'

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  timeout = Validator.get_config('timeouts','priority_completion')
  component = Validator.get_config('main_component')
  signal_group_id = Validator.get_config('components','signal_group').keys.first
  prio = Validator::StatusHelpers::SignalPriorityRequestHelper.new(
    site,
    component: component,
    signal_group_id: signal_group_id,
    timeout: timeout,
    task: task
  )
  prio.run do
    log "Before: Send unrelated signal priority request."
    prio.request_unrelated
    log "Send signal priority request, wait for reception."
    prio.request
    log "After: Send unrelated signal priority request."
    prio.request_unrelated
    prio.expect :received
    log "Signal priority request was received, wait for activation."
    prio.expect :activated
    log "Signal priority request was activated, now cancel it and wait for completion."
    prio.cancel
    prio.expect :completed
    log "Signal priority request was completed."
  end
end
```
</details>




## Signal priority becomes stale if not cancelled

Validate that a signal priority times out if not cancelled.

1. Given the site is connected
2. And we subscribe to signal priority status
3. When we send a signal priority request
4. Then the request state should become 'received'
5. Then the request state should become 'activated'
6. When we do not cancel the request
7. Then the state should become 'stale'

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  timeout = Validator.get_config('timeouts','priority_completion')
  component = Validator.get_config('main_component')
  signal_group_id = Validator.get_config('components','signal_group').keys.first
  prio = Validator::StatusHelpers::SignalPriorityRequestHelper.new(
    site,
    component: component,
    signal_group_id: signal_group_id,
    timeout: timeout,
    task: task
  )
  prio.run do
    log "Before: Send unrelated signal priority request."
    prio.request_unrelated
    log "Send signal priority request, wait for reception."
    prio.request
    log "After: Send unrelated signal priority request."
    prio.request_unrelated
    prio.expect :received
    log "Signal priority request was received, wait for activation."
    prio.expect :activated
    log "Signal priority request was activated, wait for it to become stale."
    # don't cancel request, it should then become stale by itself
    prio.expect :stale
    log "Signal priority request became stale."
  end
end
```
</details>




## Signal priority can be requested with M0022

Validate that a signal priority can be requested.

1. Given the site is connected
2. When we send a signal priority request
3. Then we should receive an acknowledgement

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  signal_group = Validator.get_config('components','signal_group').keys.first
  command_list = build_command_list :M0022, :requestPriority, {
    requestId: SecureRandom.uuid()[0..3],
    signalGroupId: signal_group,
    type: 'new',
    level: 7,
    eta: 10,
    vehicleType: 'car'
  }
  prepare task, site
  send_command_and_confirm @task, command_list,
    "Request signal priority for signal group #{signal_group}"
end
```
</details>




## Signal priority status can be fetched with S0033

Validate that signal priority status can be requested.

1. Given the site is connected
2. When we request signal priority status
3. Then we should receive a status update

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  request_status_and_confirm site, "signal group status",
    { S0033: [:status] }
end
```
</details>




## Signal priority status can be subscribed to with S0033

Validate that we can subscribe signal priority status

1. Given the site is connected
2. And we subscribe to signal priority status updates
4. Then we should receive an acknowledgement
5. And we should reive a status updates

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  prepare task, site
  status_list = [{'sCI'=>'S0033','n'=>'status','uRt'=>'0'}]
  status_list.map! { |item| item.merge!('sOc' => true) } if use_sOc?(site)
  wait_for_status task, 'signal priority status', status_list
end
```
</details>


