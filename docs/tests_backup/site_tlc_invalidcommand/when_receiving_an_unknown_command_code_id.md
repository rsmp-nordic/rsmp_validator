---
layout: page
title: when receiving an unknown command code id
parmalink: when_receiving_an_unknown_command_code_id
has_children: false
has_toc: false
parent: Site::Tlc::InvalidCommand
grand_parent: Test Suite
---

# when receiving an unknown command code id
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## When receiving an unknown command code id returns NotAck

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'returns NotAck' do
  with_site(:connected) do |site_proxy|
    log 'Sending non-existing command M0000'
    command_list = build_command_list :M0000, :bad, {}
    result = site_proxy.send_command Validator.get_config('main_component'), command_list,
                               collect: { timeout: Validator.get_config('timeouts', 'command_response') },
                               validate: false # disable validation of outgoing message
    collector = result[:collector]
    expect(collector).to be_a(RSMP::Collector)
    expect(collector.status).to eq(:cancelled)
    expect(collector.error).to be_a(RSMP::MessageRejected)
  end
end
```
</details>
