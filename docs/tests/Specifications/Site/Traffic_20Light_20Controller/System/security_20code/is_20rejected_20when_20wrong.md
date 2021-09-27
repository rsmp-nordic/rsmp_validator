---
layout: page
title: is rejected when wrong
parent: security code
---

# security code is rejected when wrong



```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  wrong_security_code 
end
```

