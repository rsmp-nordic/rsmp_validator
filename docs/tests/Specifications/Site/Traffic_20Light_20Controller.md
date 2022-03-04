---
layout: page
title: Traffic Light Controller
parmalink: traffic_light_controller
has_children: true
has_toc: false
parent: Site
grand_parent: Test Suite
---

# Traffic Light Controller
{: .no_toc}

Tests for Traffic Light Controllers.

### Categories
{: .no_toc .text-delta }
- [Alarm]({{ site.baseurl }}{% link tests/Specifications/Site/Traffic_20Light_20Controller/Alarm.md %})
- [Clock]({{ site.baseurl }}{% link tests/Specifications/Site/Traffic_20Light_20Controller/Clock.md %})
- [Detector Logic]({{ site.baseurl }}{% link tests/Specifications/Site/Traffic_20Light_20Controller/Detector_20Logic.md %})
- [Emergency Route]({{ site.baseurl }}{% link tests/Specifications/Site/Traffic_20Light_20Controller/Emergency_20Route.md %})
- [IO]({{ site.baseurl }}{% link tests/Specifications/Site/Traffic_20Light_20Controller/IO.md %})
- [Operational]({{ site.baseurl }}{% link tests/Specifications/Site/Traffic_20Light_20Controller/Operational.md %})
- [Signal Group]({{ site.baseurl }}{% link tests/Specifications/Site/Traffic_20Light_20Controller/Signal_20Group.md %})
- [Signal Plan]({{ site.baseurl }}{% link tests/Specifications/Site/Traffic_20Light_20Controller/Signal_20Plan.md %})
- [Subscription]({{ site.baseurl }}{% link tests/Specifications/Site/Traffic_20Light_20Controller/Subscription.md %})
- [System]({{ site.baseurl }}{% link tests/Specifications/Site/Traffic_20Light_20Controller/System.md %})
- [Traffic Data]({{ site.baseurl }}{% link tests/Specifications/Site/Traffic_20Light_20Controller/Traffic_20Data.md %})
- [Traffic Situation]({{ site.baseurl }}{% link tests/Specifications/Site/Traffic_20Light_20Controller/Traffic_20Situation.md %})

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Traffic light controller yellow flash can be activated with M0001 and goes back to NormalControl after one minute

Verify that we can activate yellow flash and after 1 minute goes back to NormalControl

1. Given the site is connected
2. Send the control command to switch to Normal Control, and wait for this
2. Send the control command to switch to Yellow flash
3. Wait for status Yellow flash
5. Wait for automatic revert to Normal Control

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  switch_normal_control
  minutes = 1
  switch_yellow_flash timeout_minutes: minutes
  wait_normal_control timeout: minutes*60 + Validator.config['timeouts']['functional_position']
end
```
</details>


