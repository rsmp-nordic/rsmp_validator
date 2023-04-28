---
layout: page
title: Signal Priority
parmalink: traffic_light_controller_signal_priority
has_children: false
has_toc: false
parent: Traffic Light Controller
grand_parent: Site
---

# Traffic Light Controller Signal Priority
{: .no_toc}



### Tests
{: .no_toc .text-delta }

- TOC
{:toc}

## Signal priority can be requested with M0022

Validate that a signal priority can be requested.

1. Given the site is connected
2. When we send a signal priority request
3. Then we should receive an acknowledgement

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  signal_group = Validator.config['components']['signal_group'].keys.first
  command_list = build_command_list :M0022, :requestPriority, {
    requestId: SecureRandom.uuid()[0..3],
    signalGroupId: signal_group,
    type: 'new',
    level: 7,
    eta: 10,
    vehicleType: 'car'
  }
  prepare task, site
  send_command_and_confirm @task, command_list,
    "Request signal priority for signal group #{signal_group}"
end
```
</details>




## Signal priority state goes through received, activated, completed

Validate that signal priority status are send when priorty is requested

1. Given the site is connected
2. And we subscribe to signal priority status
2. When we send a signal priority request
3. Then we should receive status updates

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  sequence = ['received','activated','completed']
  # subscribe
  component = Validator.config['main_component']
  log "Subscribing to signal priority request status updates"
  status_list = [{'sCI'=>'S0033','n'=>'status','uRt'=>'0'}]
  status_list.map! { |item| item.merge!('sOc' => 'True') } if use_sOc?(site)
  site.subscribe_to_status component, status_list
  # start collector
  request_id = SecureRandom.uuid()[0..3]    # make a message id
  num = sequence.length
  states = []
  result = nil
  collector = nil
  collect_task = task.async do
    collector = RSMP::Collector.new(
      site,
      type: "StatusUpdate",
      num: num,
      timeout: Validator.config['timeouts']['priority_completion'],
      component: component
    )
    def search_for_request_state request_id, message, states
      message.attribute('sS').each do |status|
        return nil unless status['sCI'] == 'S0033' && status['n'] == 'status'
        status['s'].each do |priority|
          next unless priority['r'] == request_id  # is this our request
          state = priority['s']
          next unless state != states.last  # did the state change?
          log "Priority request reached state '#{state}'"
          return state
        end
      end
      nil
    end
    result = collector.collect do |message|
      state = search_for_request_state request_id, message, states
      next unless state
      states << state
      :keep
    end
  end
  def send_priority_request log, id:nil, site:, component:
    # send an unrelated request before our request, to check that it does not interfere
    log log
    signal_group = Validator.config['components']['signal_group'].keys.first
    command_list = build_command_list :M0022, :requestPriority, {
      requestId: (id || SecureRandom.uuid()[0..3]),
      signalGroupId: signal_group,
      type: 'new',
      level: 7,
      eta: 2,
      vehicleType: 'car'
    }
    site.send_command component, command_list
  end
  send_priority_request "Send an unrelated signal priority request before", 
    site: site, component: component
  send_priority_request "Send our signal priority request",
    site: site, component: component, id: request_id
  send_priority_request "Send an unrelated signal priority request after",
    site: site, component: component
  # wait for collector to complete and check result
  collect_task.wait
  expect(result).to eq(:ok)
  expect(collector.messages).to be_an(Array)
  expect(collector.messages.size).to eq(num)
  expect(states).to eq(sequence), "Expected state sequence #{sequence}, got #{states}"
ensure
  # unsubcribe
  unsubscribe_list = status_list.map { |item| item.slice('sCI','n') }
  site.unsubscribe_to_status component, unsubscribe_list
end
```
</details>




## Signal priority status can be fetched with S0033

Validate that signal priority status can be requested.

1. Given the site is connected
2. When we request signal priority status
3. Then we should receive a status update

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  request_status_and_confirm site, "signal group status",
    { S0033: [:status] }
end
```
</details>




## Signal priority status can be subscribed to with S0033

Validate that we can subscribe signal priority status

1. Given the site is connected
2. And we subscribe to signal priority status updates
4. Then we should receive an acknowledgement
5. And we should reive a status updates

<details markdown="block">
  <summary>
     View Source
  </summary>
```ruby
Validator::Site.connected do |task,supervisor,site|
  prepare task, site
  status_list = [{'sCI'=>'S0033','n'=>'status','uRt'=>'0'}]
  status_list.map! { |item| item.merge!('sOc' => 'True') } if use_sOc?(site)
  wait_for_status task, 'signal priority status', status_list
end
```
</details>


