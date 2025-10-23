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

## Aggregated status receives aggregated status

Validate that the supervisor responds correctly when we send an aggregated status message

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::SupervisorTester.connected do |task,site,supervisor_proxy|
  component = site.find_component Validator.get_config('main_component')
  # setting ':collect' will cause set_aggregated_status() to wait for the
  # outgoing aggregated status is acknowledged
  component.set_aggregated_status :high_priority_alarm, collect!: {
    timeout: Validator.get_config('timeouts','acknowledgement'),
    num: 1
  }
end
```
</details>


