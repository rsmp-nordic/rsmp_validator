---
layout: page
title: when receiving a command with a bad command name n
parmalink: when_receiving_a_command_with_a_bad_command_name_n
has_children: false
has_toc: false
parent: Site::Tlc::InvalidCommand
grand_parent: Test Suite
---

# when receiving a command with a bad command name n
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## When receiving a command with a bad command name n returns NotAck

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'returns NotAck' do
  with_site(:connected) do |site_proxy|
    log 'Sending M0001'
    # for M0001, cO should be :setValue, here we use the incorrect :bad
    command_list = build_command_list :M0001, :bad, {
      securityCode: '1111',
      intersection: '0',
      timeout: '0'
    }
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
