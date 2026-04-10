---
layout: page
title: when receiving a status request for an unknown status
parmalink: when_receiving_a_status_request_for_an_unknown_status
has_children: false
has_toc: false
parent: Site::Tlc::InvalidStatus
grand_parent: Test Suite
---

# when receiving a status request for an unknown status
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## When receiving a status request for an unknown status returns NotAck

Verify that site_proxy returns NotAck when receiving
a request for an unknown status

1. Given the site_proxy is connected
2. When we send a non-existing S000 status request
3. Then the site_proxy should return NotAck

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'returns NotAck' do
  with_site(:connected) do |site_proxy|
    log 'Requesting non-existing status S0000'
    status_list = convert_status_list(S0000: [:status])
    result = site_proxy.request_status(
      Validator.get_config('main_component'), status_list,
      collect: { timeout: Validator.get_config('timeouts', 'status_response') },
      validate: false
    )
    collector = result[:collector]
    expect(collector).to be_a(RSMP::Collector)
    expect(collector.status).to eq(:cancelled)
    expect(collector.error).to be_a(RSMP::MessageRejected)
  end
end
```
</details>
