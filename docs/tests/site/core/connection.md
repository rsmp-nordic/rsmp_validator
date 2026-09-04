---
layout: page
title: Connection
parmalink: core_connection
has_children: false
has_toc: false
parent: Core
grand_parent: Site
---

# Connection
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Connection is closed if watchdogs are not acknowledged

1. Given the site has just connected
2. When our supervisor does not acknowledge watchdogs
3. Then the site should disconnect

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is closed if watchdogs are not acknowledged' do
  with_site(:isolated, sxl: '>=1.0.7') do |site_proxy|
    timeout = RSMP::Validator.get_config('timeouts', 'disconnect')
    log 'Disabling watchdog acknowledgements, site should disconnect'
    def site_proxy.acknowledge(original)
      if original.is_a? RSMP::Watchdog
        log 'Not acknowledgning watchdog', message: original
      else
        super
      end
    end
    site_proxy.wait_for_state!(:disconnected, timeout: timeout)
  end
end
```
</details>


## Connection is not closed if watchdogs are not received

1. Given the site has just connected
2. When our supervisor stops sending watchdogs
3. Then the site should not disconnect

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'is not closed if watchdogs are not received' do
  with_site(:isolated, sxl: '>=1.0.7') do |site_proxy|
    timeout = RSMP::Validator.get_config('timeouts', 'disconnect')
    log 'Stop sending watchdogs, site should not disconnect'
    site_proxy.with_watchdog_disabled do
      result = site_proxy.wait_for_state :disconnected, timeout: timeout
      assert(result.failure? && result.failure.code == :timeout,
             "Site disconnected unexpectedly: #{result.inspect}")
    end
  end
end
```
</details>
