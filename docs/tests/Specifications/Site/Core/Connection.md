---
layout: page
title: Connection
parmalink: core_connection
has_children: false
has_toc: false
parent: Core
grand_parent: Site
---

# Core Connection
{: .no_toc}

{{ site.base_url }}
Check that the site closed the connection as required when faced with
various types of incorrect behaviour from our side.

The site object passed by Validator::Site a SiteProxy object. We can redefine methods
on this object to modify behaviour after the connection has been established. To ensure
that the modfid SityProxy is not reused in later tests, we use  Validator::Site.isolate,
rather than the more common Validator::Site.connect.

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Connection is closed if watchdogs are not acknowledged

1. Given the site is new and connected
2. When site watchdog acknowledgement method is changed to do nothing
3. Then the site should disconnect

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.isolated do |task,supervisor,site|
  def site.acknowledge original
  end
  timeout = Validator.config['timeouts']['disconnect']
  site.wait_for_state :stopped, timeout
rescue RSMP::TimeoutError
  raise "Site did not disconnect within #{timeout}s"
end
```
</details>




## Connection is closed if watchdogs are not received

1. Given the site is new and connected
2. When site watchdog sending method is changed to do nothing
3. Then the supervisor should disconnect

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.isolated do |task,supervisor,site|
  def site.send_watchdog now=nil
  end
  timeout = Validator.config['timeouts']['disconnect']
  site.wait_for_state :stopped, timeout
rescue RSMP::TimeoutError
  raise "Site did not disconnect within #{timeout}s"
end
```
</details>


