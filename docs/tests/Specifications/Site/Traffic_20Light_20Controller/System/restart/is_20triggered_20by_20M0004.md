---
layout: page
title: is triggered by M0004
parent: restart
---

# restart is triggered by M0004

1. Verify connection i Isolated_mode
2. Send the control command to restart, include security_code
3. Wait for status response= stopped
4. Reconnect as Isolated_mode
5. Wait for status= ready
6. Send command to switch to normal controll
7. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true

```ruby
Validator::Site.isolated do |task,supervisor,site|
  prepare task, site
  #if ask_user site, "Going to restart controller. Press enter when ready or 's' to skip:"
  set_restart
  site.wait_for_state :stopped, Validator.config['timeouts']['shutdown']
end
# NOTE
# when a remote site closes the connection, our site proxy object will stop.
# when the site reconnects, a new site proxy object will be created.
# this means we can't wait for the old site to become ready
# it also means we need a new Validator::Site.
Validator::Site.isolated do |task,supervisor,site|
  prepare task, site
  site.wait_for_state :ready, Validator.config['timeouts']['ready']
  wait_normal_control
end
```

