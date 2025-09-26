---
layout: page
title: Subscription
parmalink: traffic_light_controller_subscription
has_children: false
has_toc: false
parent: Traffic Light Controller
grand_parent: Site
---

# Traffic Light Controller Subscription
{: .no_toc}



### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Subscription can be turned on and off for S0001

Check that we can *subscribe* to status messages.
The test subscribes to S0001 (signal group status), because
it will usually change once per second, but otherwise the choice
is arbitrary as we simply want to check that
the subscription mechanism works.

1. subscribe
1. check that we receive a status update with a predefined time
1. unsubscribe

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  log "Subscribe to status and wait for update"
  component = Validator.get_config('main_component')
  status_list = [{'sCI'=>'S0001','n'=>'signalgroupstatus','uRt'=>'1'}]
  status_list.map! { |item| item.merge!('sOc' => true) } if use_sOc?(site)
   site.subscribe_to_status component, status_list, collect!: {
    timeout: Validator.get_config('timeouts','status_update')
  }
ensure
  unsubscribe_list = status_list.map { |item| item.slice('sCI','n') }
  site.unsubscribe_to_status component, unsubscribe_list
end
```
</details>




## Subscription can change interval during active subscription

Check that we can change the update rate interval while status subscription is active.
The test subscribes to S0001 'cyclecounter' attribute with an initial update rate of 60s,
then changes the update rate to 1s and verifies the new rate is in effect.

1. Subscribe to S0001 'cyclecounter' with update rate 60s
2. Verify that subscription succeeds
3. Send the same subscription again with update rate 1s
4. Verify that the new update rate is in effect by checking next update is received within 2s

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  component = Validator.get_config('main_component')
  
  # Step 1: Subscribe with 60s update rate (no need to wait for updates with long interval)
  log "Subscribe to S0001 cyclecounter with 60s update rate"
  initial_status_list = [{'sCI'=>'S0001','n'=>'cyclecounter','uRt'=>'60'}]
  initial_status_list.map! { |item| item.merge!('sOc' => true) } if use_sOc?(site)
  # Subscribe but don't wait for updates (since 60s is too long)
  site.subscribe_to_status component, initial_status_list
  log "Initial subscription with 60s update rate successful"
  # Step 3: Change update rate to 1s by re-subscribing and verify we get update within 2s
  log "Change update rate to 1s by re-subscribing and verify update within 2s"
  updated_status_list = [{'sCI'=>'S0001','n'=>'cyclecounter','uRt'=>'1'}]
  updated_status_list.map! { |item| item.merge!('sOc' => true) } if use_sOc?(site)
  # This should collect at least one status update within 2s if the 1s rate is working
  result = site.subscribe_to_status component, updated_status_list, collect!: {
    timeout: 2
  }
  
  expect(result).to_not be_nil
  expect(result[:collector].messages).to_not be_empty, "Expected to receive status update within 2s with new 1s update rate"
  log "Successfully received status update within 2s, confirming 1s update rate is active"
ensure
  # Clean up subscription
  unsubscribe_list = [{'sCI'=>'S0001','n'=>'cyclecounter'}]
  site.unsubscribe_to_status component, unsubscribe_list
end
```
</details>


