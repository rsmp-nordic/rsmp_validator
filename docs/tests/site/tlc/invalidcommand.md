---
layout: page
title: Invalid Command
parmalink: tlc_invalidcommand
has_children: false
has_toc: false
parent: Tlc
grand_parent: Site
---

# Invalid Command
{: .no_toc}

### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Invalid Command returns NotAck if attribute is missing

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'returns NotAck if attribute is missing' do
  with_site(:connected) do |site_proxy|
    log "Sending M0001 with 'status' attribute missing"
    command_list = RSMP::CommandList.new(:M0001, :setValue,
                                         securityCode: '1111',
                                         intersection: '0',
                                         timeout: '0').to_a
    # intentionally not setting 'status'
    timeout = RSMP::Validator.get_config('timeouts', 'command_response')
    result = site_proxy.send_command_and_collect(command_list,
                                                 within: timeout,
                                                 validate: false) # disable validation of outgoing message
    expect_message_rejected(result)
  end
end
```
</details>


## Invalid Command returns NotAck if command code id is unknown

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'returns NotAck if command code id is unknown' do
  with_site(:connected) do |site_proxy|
    log 'Sending non-existing command M0000'
    command_list = RSMP::CommandList.new(:M0000, :bad, {}).to_a
    timeout = RSMP::Validator.get_config('timeouts', 'command_response')
    result = site_proxy.send_command_and_collect(command_list,
                                                 within: timeout,
                                                 validate: false) # disable schema validation of outgoing message
    expect_message_rejected(result)
  end
end
```
</details>


## Invalid Command returns NotAck if command name is bad

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'returns NotAck if command name is bad' do
  with_site(:connected) do |site_proxy|
    log 'Sending M0001'
    # for M0001, cO should be :setValue, here we use the incorrect :bad
    command_list = RSMP::CommandList.new(:M0001, :bad,
                                         securityCode: '1111',
                                         intersection: '0',
                                         timeout: '0').to_a
    timeout = RSMP::Validator.get_config('timeouts', 'command_response')
    result = site_proxy.send_command_and_collect(command_list,
                                                 within: timeout,
                                                 validate: false) # disable validation of outgoing message
    expect_message_rejected(result)
  end
end
```
</details>


## Invalid Command returns a command response with age=undefined if compoent id is unknown

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
it 'returns a command response with age=undefined if compoent id is unknown' do
  with_site(:connected, core: '>=3.1.3') do |site_proxy|
    log 'Sending M0001'
    command_list = RSMP::CommandList.new(:M0001, :setValue,
                                         securityCode: RSMP::Validator.get_config('secrets', 'security_codes', 2),
                                         status: 'NormalControl',
                                         timeout: '0',
                                         intersection: '0').to_a
    result = site_proxy.send_command_and_collect(
      command_list,
      component: 'bad',
      within: RSMP::Validator.get_config('timeouts', 'command_response'),
      validate: false # disable validation of outgoing message
    )
    exchange = result.value!
    response = exchange.messages.first
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
