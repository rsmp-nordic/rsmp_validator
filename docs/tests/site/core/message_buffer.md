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

## Message Buffer marks buffered status values as old for rsmp 3.2 and later

Verify that buffered status messages use quality "old" for core versions
where the core spec requires it.

1. Given the site is connected using core 3.2 or later
2. And a status subscription is active
3. When communication is disrupted and later restored
4. Then buffered status values should have q=old

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'marks buffered status values as old for rsmp 3.2 and later' do
  skip 'requires core >= 3.2' unless RSMP::Validator.core_matches?('>=3.2')
  update = collect_buffered_status_after_disruption
  expect(update.attributes['sS'].map { |status| status['q'] }.uniq).to be == ['old']
end
```
</details>


## Message Buffer preserves buffered status timestamps from before reconnect

Verify that buffered status timestamps reflect when the status data was
generated, not when the buffered message was sent after reconnect.

1. Given the site is connected and a status subscription is active
2. When communication is disrupted long enough for a status update to be due
3. And communication is restored
4. Then the buffered status timestamp should be older than the reconnect

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'preserves buffered status timestamps from before reconnect' do
  skip 'requires core >= 3.1.4' unless RSMP::Validator.core_matches?('>=3.1.4')
  result = collect_buffered_status_after_disruption_with_timing
  status_time = Time.parse(result[:update].attributes['sTs'])
  assert(status_time < result[:reconnect_started_at],
         "expected buffered status timestamp #{status_time} to be before reconnect " \
         "#{result[:reconnect_started_at]}")
end
```
</details>


## Message Buffer sends buffered status messages after communication is restored

Verify that a site sends buffered status messages after communication is restored.

1. Given the site is connected and a status subscription is active
2. When communication is disrupted long enough for a status update to be due
3. And communication is restored
4. Then the site should send the buffered status update

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'sends buffered status messages after communication is restored' do
  skip 'requires core >= 3.1.4' unless RSMP::Validator.core_matches?('>=3.1.4')
  update = collect_buffered_status_after_disruption
  expect(update).to be_a(RSMP::StatusUpdate)
  assert(!update.attributes['sS'].empty?, 'expected buffered status update to include status values')
end
```
</details>
