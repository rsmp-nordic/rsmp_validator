---
layout: page
title: Subscribe
parmalink: tlc_subscribe
has_children: false
has_toc: false
parent: Tlc
grand_parent: Site
---

# Subscribe
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Subscribe can be turned on and off for S0001

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'can be turned on and off for S0001' do
  with_site(:connected) do |site_proxy|
    log 'Subscribe to status and wait for update'
    component = Validator.get_config('main_component')
    status_list = [{ 'sCI' => 'S0001', 'n' => 'signalgroupstatus', 'uRt' => '1' }]
    status_list.map! { |item| item.merge!('sOc' => true) } if site_proxy.tlc.use_soc?
    site_proxy.subscribe_to_status_and_collect(status_list,
                                               component: component,
                                               within: Validator.get_config('timeouts', 'status_update')).ok!
  ensure
    unsubscribe_list = status_list.map { |item| item.slice('sCI', 'n') }
    site_proxy.unsubscribe_to_status unsubscribe_list, component: component
  end
end
```
</details>


## Subscribe can change interval during active subscription

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'can change interval during active subscription' do
  with_site(:connected) do |site_proxy|
    component = Validator.get_config('main_component')
    # Step 1: Subscribe with 60s update rate (no need to wait for updates with long interval)
    log 'Subscribe to S0001 cyclecounter with 60s update rate'
    initial_status_list = [{ 'sCI' => 'S0001', 'n' => 'cyclecounter', 'uRt' => '60' }]
    initial_status_list.map! { |item| item.merge!('sOc' => true) } if site_proxy.tlc.use_soc?
    # Subscribe but don't wait for updates (since 60s is too long)
    site_proxy.subscribe_to_status initial_status_list, component: component
    log 'Initial subscription with 60s update rate successful'
    # Step 3: Change update rate to 1s by re-subscribing and verify we get update within 2s
    log 'Change update rate to 1s by re-subscribing and verify update within 2s'
    updated_status_list = [{ 'sCI' => 'S0001', 'n' => 'cyclecounter', 'uRt' => '1' }]
    updated_status_list.map! { |item| item.merge!('sOc' => true) } if site_proxy.tlc.use_soc?
    # This should collect at least one status update within 2s if the 1s rate is working
    collector = site_proxy.subscribe_to_status_and_collect(updated_status_list,
                                                           component: component,
                                                           within: 2).ok!
    assert(!collector.nil?, 'Expected subscribe_to_status_and_collect to return a collector')
    assert(!collector.messages.empty?,
           'Expected to receive status update within 2s with new 1s update rate')
    log 'Successfully received status update within 2s, confirming 1s update rate is active'
  ensure
    # Clean up subscription
    unsubscribe_list = [{ 'sCI' => 'S0001', 'n' => 'cyclecounter' }]
    site_proxy.unsubscribe_to_status unsubscribe_list, component: component
  end
end
```
</details>
