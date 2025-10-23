---
layout: page
title: Aggregated Status
parmalink: core_aggregated_status
has_children: false
has_toc: false
parent: Core
grand_parent: Site
---

# Core Aggregated Status
{: .no_toc}



### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Aggregated status can be requested

Verify that the controller responds to an aggregated status request.

1. Given the site is connected
2. When we request aggregated status
3. Then we should receive an aggregated status

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.connected do |task,supervisor,site|
  prepare task, site
  log "Request aggregated status"
  result = site.request_aggregated_status Validator.get_config('main_component'), collect!: {
    timeout: Validator.get_config('timeouts','status_response')
  }
end
```
</details>




## Aggregated status uses null for functional position/state

Verify that aggregated status uses null for unused attributes, from SXL 1.1
For SXL versions before 1.1 empty strings "" is also allowed.

1. Given the is reconnected
2. When we receive an aggregated status
3. Then fP and fS should be null

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SiteTester.isolated(
  'collect' => {
    filter: RSMP::Filter.new(type:"AggregatedStatus"),
    timeout: Validator.get_config('timeouts','ready'),
    num: 1,
    ingoing: true
  }
) do |task,supervisor,site_proxy|
  collector = site_proxy.collector
  collector.use_task task
  collector.wait!
  aggregated_status = site_proxy.collector.messages.first
  expect(aggregated_status).to be_an(RSMP::AggregatedStatus)
  expect(aggregated_status.attribute('fP')).to be_nil
  expect(aggregated_status.attribute('fS')).to be_nil
end
```
</details>


