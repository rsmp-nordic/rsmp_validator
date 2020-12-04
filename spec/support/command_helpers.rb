def log_confirmation action, &block
  @site.log "Confirming #{action}", level: :test
  start_time = Time.now
  yield block
  delay = Time.now - start_time
  upcase_first = action.sub(/\S/, &:upcase)
  @site.log "#{upcase_first} confirmed after #{delay.to_i}s", level: :test
rescue RSpec::Expectations::ExpectationNotMetError => e
  @site.log "Could not confirm #{action}: #{e.to_s}", level: :test 
  raise e 
end

def unsubscribe_from_all
  @site.unsubscribe_to_status @component, [
    {'sCI'=>'S0015','n'=>'status'},
    {'sCI'=>'S0014','n'=>'status'},
    {'sCI'=>'S0011','n'=>'status'},
    {'sCI'=>'S0009','n'=>'status'},
    {'sCI'=>'S0007','n'=>'status'},
    {'sCI'=>'S0006','n'=>'status'},
    {'sCI'=>'S0006','n'=>'emergencystage'},
    {'sCI'=>'S0005','n'=>'status'},
    {'sCI'=>'S0003','n'=>'inputstatus'},
    {'sCI'=>'S0002','n'=>'detectorlogicstatus'},
    {'sCI'=>'S0001','n'=>'signalgroupstatus'},
    {'sCI'=>'S0001','n'=>'cyclecounter'},
    {'sCI'=>'S0001','n'=>'basecyclecounter'},
    {'sCI'=>'S0001','n'=>'stage'}
  ]
end

def subscribe status_list, update_rate: RSMP_CONFIG['status_update_rate']
  sub_list = status_list.map { |item| item.slice('sCI','n').merge 'uRt'=>update_rate.to_s }
  expect do
    @site.subscribe_to_status @component, sub_list, RSMP_CONFIG['subscribe_timeout']
  end.to_not raise_error
end

def verify_status status_list:, description:
  log_confirmation description do
    expect do
      from_index = @site.archive.items.size #get index before we subscribe
      subscribe status_list
      response = nil
      @site.wait_for_status_updates({
        component: @component,
        status_list: status_list,
        from: from_index,  #backscan starting from index 
        timeout: RSMP_CONFIG['status_timeout']
      }) 
    end.to_not raise_error, "Did not receive status"
    unsubscribe_from_all
  end
end

def send_command_and_confirm command_list, message, component=@component
  log_confirmation message do
    response = nil
    expect do
      backscan_from = @site.archive.current_index
      sent = @site.send_command component, command_list
      #@site.wait_for_acknowledgement sent, RSMP_CONFIG['command_timeout']
      response = @site.wait_for_command_responses({
        request: sent,
        component: component, 
        command_list: command_list,
        backscan_from: backscan_from,
        timeout: RSMP_CONFIG['command_timeout']
      })
    end.to_not raise_error

    #expected_response = command_list.map do |item|
    #  item2 = item.clone
    #  item2.delete 'cO'
    #  item2['age'] = 'recent'
    #  item2
    #end
    #expect(response.attributes['rvs']).to eq expected_response
  end
end

def build_command_list command_code_id, command_name, values
  values.to_a.map do |n,v|
    {
      'cCI' => command_code_id.to_s,
      'cO' => command_name.to_s,
      'n' => n.to_s,
      'v' => v.to_s
    }
  end
end

def set_plan plan
  @site.log "Switching to traffic situation #{plan}", level: :test
  command_list = build_command_list :M0002, :setPlan, {
    securityCode: SECRETS['security_codes'][2],
    timeplan: plan
  }
  send_command_and_confirm command_list, "intention to switch to plan #{plan}"
end

# Note the spelling error 'traficsituation'. This should be fixed in future version
def set_traffic_situation ts
  @site.log "Switching to traffic situation #{ts}", level: :test
  command_list = build_command_list :M0003, :setTrafficSituation, {
    securityCode: SECRETS['security_codes'][2],
    traficsituation: ts
  }
  send_command_and_confirm command_list, "intention to switch to traffic situation #{ts}"
end

def set_functional_position status
  @site.log "Switching to #{status}", level: :test
  command_list = build_command_list :M0001, :setValue, {
    securityCode: SECRETS['security_codes'][2],
    status: status,
    timeout: 0,
    intersection: 0 
  }
  send_command_and_confirm command_list, "intention to switch to #{status}"
end

def set_fixed_time status
  @site.log "Switching to fixed time #{status}", level: :test
  command_list = build_command_list :M0007, :setFixedTime, {
    securityCode: SECRETS['security_codes'][2],
    status: status
  }
  send_command_and_confirm command_list, "intention to switch to fixed time #{status}"
end

def set_restart
  @site.log "Restarting traffic controller", level: :test
  command_list = build_command_list :M0004, :setRestart, {
    securityCode: SECRETS['security_codes'][2],
    status: 'True'
  }
  @site.send_command @component, command_list
  # if the controller restarts immediately, we will not receive a command response,
  # so do not expect this
end

def set_emergency_route status, route
  @site.log "Set emergency route #{route}", level: :test
  command_list = build_command_list :M0005, :setEmergency, {
    securityCode: SECRETS['security_codes'][2],
    emergencyroute: route
  }
  send_command_and_confirm command_list, "intention to switch to emergency route #{route}"
end

def set_input status, input
  @site.log "Set input #{input}", level: :test
  command_list = build_command_list :M0006, :setInput, {
    securityCode: SECRETS['security_codes'][2],
    input: input
  }
  send_command_and_confirm command_list, "intention to set input #{input}"
end

def force_detector_logic component, status, mode='True'
  @site.log "Force detector logic", level: :test
  command_list = build_command_list :M0008, :setForceDetectorLogic, {
    securityCode: SECRETS['security_codes'][2],
    status: status,
    mode: mode
  }
  send_command_and_confirm command_list, "intention to force detector logic #{status} to #{mode}", component
end

def switch_plan plan
  set_plan plan.to_s
  verify_status(**{
    description: "switch to plan #{plan}",
    status_list: [{'sCI'=>'S0014','n'=>'status','s'=>plan.to_s}]
  })
end

def switch_traffic_situation ts
  set_traffic_situation ts
  verify_status(**{
    description: "switch to traffic situation #{ts}",
    status_list: [{'sCI'=>'S0015','n'=>'status','s'=>ts}]
  })
end

def switch_yellow_flash
  set_functional_position 'YellowFlash'
  verify_status(**{
    description:"switch to yellow flash",
    status_list:[{'sCI'=>'S0011','n'=>'status','s'=>/^True(,True)*$/}]
  })
end

def switch_dark_mode
  set_functional_position 'Dark'
  verify_status(**{
    description:"switch to dark mode",
    status_list:[{'sCI'=>'S0007','n'=>'status','s'=>/^False(,False)*$/}]
  })
end

def wait_normal_control
  # Wait for 'switched on' to be true (dark mode false)
  verify_status(**{
    description:"dark mode off",
    status_list:[{'sCI'=>'S0007','n'=>'status','s'=>/^True(,True)*$/}]
  })

  # Wait for yellow flash status to be false
  verify_status(**{
    description:"yellow flash off",
    status_list:[{'sCI'=>'S0011','n'=>'status','s'=>/^False(,False)*$/}]
  })

  # Wait for startup mode to be false
  verify_status(**{
    description:"start-up mode off",
    status_list:[{'sCI'=>'S0005','n'=>'status','s'=>'False'}]
  })

  unsubscribe_from_all
end

def switch_normal_control
  set_functional_position 'NormalControl'
  wait_normal_control
end

def switch_fixed_time status
  set_fixed_time status
  verify_status(**{
    description:"switch to fixed time #{status}",
    status_list:[{'sCI'=>'S0009','n'=>'status','s'=>/^#{status}(,#{status})*$/}]
  })
end

def switch_emergency_route route
  set_emergency_route 'True',route
  verify_status(**{
    description:"activate emergency route",
    status_list:[{'sCI'=>'S0006','n'=>'status','s'=>'True'}]
  })
  verify_status(**{
    description:"activate emergency route #{route}",
    status_list:[{'sCI'=>'S0006','n'=>'emergencystage','s'=>route}]
  })

  set_emergency_route 'False',route
  verify_status(**{
    description:"deactivate emergency route",
    status_list:[{'sCI'=>'S0006','n'=>'status','s'=>'False'}]
  })
end

def switch_input
  indx = 0
  set_input 'True',indx.to_s
  verify_status(**{
    description:"activate input #{indx}",
    status_list:[{'sCI'=>'S0003','n'=>'inputstatus','s'=>/^.{#{indx}}1/}]
  })

  set_input 'False',indx.to_s
  verify_status(**{
    description:"deactivate input #{indx}",
    status_list:[{'sCI'=>'S0003','n'=>'inputstatus','s'=>/^.{#{indx}}0/}]
  })
end

def switch_detector_logic
  indx = 0
  component = COMPONENT_CONFIG['detector_logic'].keys[indx]

  force_detector_logic component, 'True', 'True'
  @component = MAIN_COMPONENT
  verify_status(**{
    description:"activate detector logic #{component}",
    status_list:[{'sCI'=>'S0002','n'=>'detectorlogicstatus','s'=>/^.{#{indx}}1/}]
  })
  

  force_detector_logic component, 'False'
  @component = MAIN_COMPONENT
  verify_status(**{
    description:"deactivate detector logic #{component}",
    status_list:[{'sCI'=>'S0002','n'=>'detectorlogicstatus','s'=>/^.{#{indx}}0/}]
  })
end

def prepare task, site
  @component = MAIN_COMPONENT
  @task = task
  @site = site
  unsubscribe_from_all
end