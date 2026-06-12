---
layout: page
title: Aggregated Status
parmalink: aggregated_status
has_children: false
has_toc: false
parent: Supervisor
grand_parent: Test Suite
---

# Aggregated Status
{: .no_toc}

Validate behaviour related to aggregated status messages

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Aggregated Status receives aggregated status

Validate that the supervisor responds correctly when we send an aggregated status message

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'receives aggregated status' do
  with_supervisor(:connected) do |supervisor_proxy|
    component = supervisor_proxy.node.find_component RSMP::Validator.get_config('main_component')
    # setting ':collect' will cause set_aggregated_status() to wait for the
    # outgoing aggregated status is acknowledged
    component.set_aggregated_status :high_priority_alarm, collect!: {
      timeout: RSMP::Validator.get_config('timeouts', 'acknowledgement'),
      num: 1
    }
  end
end
```
</details>
