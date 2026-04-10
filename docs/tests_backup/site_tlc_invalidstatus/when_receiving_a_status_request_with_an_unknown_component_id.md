---
layout: page
title: when receiving a status request with an unknown component id
parmalink: when_receiving_a_status_request_with_an_unknown_component_id
has_children: false
has_toc: false
parent: Site::Tlc::InvalidStatus
grand_parent: Test Suite
---

# when receiving a status request with an unknown component id
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## When receiving a status request with an unknown component id return a command response with age=undefined

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'return a command response with age=undefined' do
  with_site(:connected, core: '>=3.1.3') do |site_proxy|
    log 'Sending M0001 with bad component id'
    status_list = convert_status_list(S0001: [:signalgroupstatus])
    result = site_proxy.request_status(
      'bad',
      status_list,
      collect: { timeout: Validator.get_config('timeouts', 'status_response') },
      validate: false
    )
    collector = result[:collector]
    expect(collector).to be_a(RSMP::Collector)
    expect(collector.status).to eq(:ok)
    response = collector.messages.first
    expect(response).to be_a(RSMP::StatusResponse)
    ss = response.attributes['sS']
    expect(ss).to be_a(Array)
    ss.each do |s|
      q = s['q']
      expect(q).to eq('undefined')
    end
  end
end
```
</details>
