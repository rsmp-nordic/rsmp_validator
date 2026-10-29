---
layout: page
title: Message Buffer
parmalink: core_message_buffer
has_children: false
has_toc: false
parent: Core
grand_parent: Site
---

# Message Buffer
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Message Buffer marks buffered status values as old for rsmp 3.2.0 and later

Verify that buffered status messages use quality "old" for core versions
where the core spec requires it.

1. Given the site is connected using core 3.2.0 or later
2. And a status subscription is active
3. When communication is disrupted and later restored
4. Then buffered status values should have q=old

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'marks buffered status values as old for rsmp 3.2.0 and later' do
  skip 'requires core >= 3.2.0' unless RSMP::Validator.core_matches?('>=3.2.0')
  initial_timestamp = with_site(:connected) { |site_proxy| subscribe_to_status(site_proxy) }
  outage_window = simulate_outage(initial_timestamp)
  with_site(:connected, 'collect' => queue_factory) do |site_proxy|
    buffered_update, = wait_for_buffered_update(site_proxy.collector, outage_window)
    assert(buffered_update, assert_message(buffered_update, outage_window))
    next unless buffered_update # skip the rest if no message was received
    assert(buffered_update.attribute('sS').all? { |status| status['q'] == 'old' }, 'Each status values have q=old')
  ensure
    site_proxy.collector.stop
    site_proxy.unsubscribe_to_status! status_list, component: component
  end
end
```
</details>


## Message Buffer sends status updates timestamped during the communication outage

Verify that historical status data arrives after communication is restored.

1. Given the site is connected and a status subscription is active
2. When communication is disrupted long enough for a status update to be due
3. And communication is restored
4. Then an update timestamped within the outage should arrive, even if fresh updates arrive first

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'sends status updates timestamped during the communication outage' do
  skip 'requires core >= 3.1.4' unless RSMP::Validator.core_matches?('>=3.1.4')
  initial_timestamp = with_site(:connected) { |site_proxy| subscribe_to_status(site_proxy) }
  outage_window = simulate_outage(initial_timestamp)
  with_site(:connected, 'collect' => queue_factory) do |site_proxy|
    buffered_message, = wait_for_buffered_update(site_proxy.collector, outage_window)
    assert(buffered_message, assert_message(buffered_message, outage_window))
  ensure
    site_proxy.collector.stop
    site_proxy.unsubscribe_to_status! status_list, component: component
  end
end
```
</details>
