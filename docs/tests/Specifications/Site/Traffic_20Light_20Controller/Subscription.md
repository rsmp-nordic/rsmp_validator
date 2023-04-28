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
  component = Validator.config['main_component']
  status_list = [{'sCI'=>'S0001','n'=>'signalgroupstatus','uRt'=>'1'}]
  status_list.map! { |item| item.merge!('sOc' => 'False') } if use_sOc?(site)
   site.subscribe_to_status component, status_list, collect!: {
    timeout: Validator.config['timeouts']['status_update']
  }
ensure
  unsubscribe_list = status_list.map { |item| item.slice('sCI','n') }
  site.unsubscribe_to_status component, unsubscribe_list
end
```
</details>

