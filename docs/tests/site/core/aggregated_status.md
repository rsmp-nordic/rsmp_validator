---
layout: page
title: Aggregated Status
parmalink: core_aggregated_status
has_children: false
has_toc: false
parent: Core
grand_parent: Site
---

# Aggregated Status
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Aggregated Status can be requested

Verify that the controller responds to an aggregated status request.

1. Given the site is connected
2. When we request aggregated status
3. Then we should receive an aggregated status

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'can be requested' do
  with_site(:connected, core: '>=3.1.5') do |site_proxy|
    log 'Request aggregated status'
    site_proxy.request_aggregated_status_and_collect(
      Validator.get_config('main_component'),
      within: Validator.get_config('timeouts', 'status_response')
    ).ok!
  end
end
```
</details>


## Aggregated Status uses null for functional position/state

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
it 'uses null for functional position/state' do
  with_site(:isolated, sxl: '>=1.1',
                       'collect' => {
                         filter: RSMP::Filter.new(type: 'AggregatedStatus'),
                         timeout: Validator.get_config('timeouts', 'ready'),
                         num: 1,
                         ingoing: true
                       }) do |site_proxy|
    collector = site_proxy.collector
    collector.use_task Async::Task.current
    collector.wait!
    aggregated_status = site_proxy.collector.messages.first
    expect(aggregated_status).to be_a(RSMP::AggregatedStatus)
    expect(aggregated_status.attribute('fP')).to be_nil
    expect(aggregated_status.attribute('fS')).to be_nil
  end
end
```
</details>
