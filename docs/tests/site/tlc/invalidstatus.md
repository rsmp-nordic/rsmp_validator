---
layout: page
title: Invalid Status
parmalink: tlc_invalidstatus
has_children: false
has_toc: false
parent: Tlc
grand_parent: Site
---

# Invalid Status
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Invalid Status return a command response with age=undefined when component id is unknown

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'return a command response with age=undefined when component id is unknown' do
  with_site(:connected, core: '>=3.1.3') do |site_proxy|
    log 'Sending M0001 with bad component id'
    collector = site_proxy.request_status_and_collect(
      { S0001: [:signalgroupstatus] },
      component: 'bad',
      within: RSMP::Validator.get_config('timeouts', 'status_response'),
      validate: false
    )
    collector.ok!
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


## Invalid Status returns NotAck when status code is unknown

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
it 'returns NotAck when status code is unknown' do
  with_site(:connected) do |site_proxy|
    log 'Requesting non-existing status S0000'
    expect do
      site_proxy.request_status_and_collect(
        { S0000: [:status] },
        component: RSMP::Validator.get_config('main_component'),
        within: RSMP::Validator.get_config('timeouts', 'status_response'),
        validate: false
      ).ok!
    end.to raise_exception(RSMP::MessageRejected)
  end
end
```
</details>


## Invalid Status returns NotAck when status name is unknown

Verify that site_proxy returns NotAck when receiving
a request for an unknown status

1. Given the site_proxy is connected
2. When we send an S0001 request with the stauts name 'bad'
3. Then the site_proxy should return NotAck

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'returns NotAck when status name is unknown' do
  with_site(:connected) do |site_proxy|
    log 'Requesting S0001 with non-existing status name'
    expect do
      site_proxy.request_status_and_collect(
        { S0001: [:bad] },
        component: RSMP::Validator.get_config('main_component'),
        within: RSMP::Validator.get_config('timeouts', 'status_response'),
        validate: false
      ).ok!
    end.to raise_exception(RSMP::MessageRejected)
  end
end
```
</details>
