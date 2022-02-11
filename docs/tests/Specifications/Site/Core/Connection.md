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
timeout = Validator.config['timeouts']['disconnect']
Validator::Site.isolated do |task,supervisor,site|
  supervisor.ignore_errors RSMP::DisconnectError do
    Validator.log "Disabling acknowledgements, site should disconnect", level: :test
    def site.acknowledge original
    end
    site.wait_for_state :disconnected, timeout: timeout
  end
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
  timeout = Validator.config['timeouts']['disconnect']
  supervisor.ignore_errors RSMP::DisconnectError do
    Validator.log "Disabling watchdogs, site should disconnect", level: :test
    def site.send_watchdog now=nil
    end
    site.wait_for_state :disconnected, timeout: timeout
  end
rescue RSMP::TimeoutError
  raise "Site did not disconnect within #{timeout}s"
end
```
</details>


