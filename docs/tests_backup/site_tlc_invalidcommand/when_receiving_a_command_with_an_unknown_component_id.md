---
layout: page
title: when receiving a command with an unknown component id
parmalink: when_receiving_a_command_with_an_unknown_component_id
has_children: false
has_toc: false
parent: Site::Tlc::InvalidCommand
grand_parent: Test Suite
---

# when receiving a command with an unknown component id
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## When receiving a command with an unknown component id returns a command response with age=undefined

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'returns a command response with age=undefined' do
  with_site(:connected, core: '>=3.1.3') do |site_proxy|
    log 'Sending M0001'
    command_list = build_command_list :M0001, :setValue, {
      securityCode: Validator.get_config('secrets', 'security_codes', 2),
      status: 'NormalControl',
      timeout: 0,
      intersection: 0
    }
    result = site_proxy.send_command(
      'bad',
      command_list,
      collect: { timeout: Validator.get_config('timeouts', 'command_response') },
      validate: false # disable validation of outgoing message
    )
    collector = result[:collector]
    expect(collector).to be_a(RSMP::Collector)
    expect(collector.status).to eq(:ok)
    response = collector.messages.first
    expect(response).to be_a(RSMP::CommandResponse)
    rvs = response.attributes['rvs']
    expect(rvs).to be_a(Array)
    rvs.each do |rv|
      age = rv['age']
      expect(age).to eq('undefined')
    end
  end
end
```
</details>
