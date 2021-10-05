---
layout: page
title: Aggregated Status
parmalink: core_aggregated_status
has_children: false
has_toc: false
parent: Core
grand_parent: Site
---

# Core Aggregated Status
{: .no_toc}



### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Aggregated status can be requested

Verify that the controller responds to an aggregated status request.

1. Given the site is connected
2. Request aggregated status 
3. Expect aggregated status response before timeout

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  log_confirmation "request aggregated status" do
    site.request_aggregated_status Validator.config['main_component'], collect: {
      timeout: Validator.config['timeouts']['status_response']
    }
  end
end
```
</details>


