# Test command requests by sending commands and checking 
# responses and status updates

def log_confirmation action, &block
  @site.log "Confirming #{action}", level: :test
  start_time = Time.now
  yield block
  delay = Time.now - start_time
  upcase_first = action.sub(/\S/, &:upcase)
  @site.log "#{upcase_first} confirmed after #{delay.to_i}s", level: :test
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

def subscribe status_list, update_rate: 1
  sub_list = status_list.map { |item| item.slice('sCI','n').merge 'uRt'=>update_rate.to_s }
  expect do
    @site.subscribe_to_status @component, sub_list, RSMP_CONFIG['subscribe_timeout']
  end.to_not raise_error
end

def set_functional_position status
  timeout = '0'
  intersection = '0'
  security_code = SECRETS['security_codes'][2]

  @site.log "Switching to #{status}", level: :test
  command_code_id = 'M0001'
  command_name = 'setValue'
  message = nil

  message = @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'timeout', 'v' => timeout},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'intersection', 'v' => intersection}
  ]

  log_confirmation"intention to switch to #{status}" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'securityCode','v' => security_code, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'timeout','v' => timeout, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'intersection','v' => intersection, 'age' => age }
    ])
  end
end

def set_plan plan
  status = 'True'
  security_code = SECRETS['security_codes'][2]

  @site.log "Switching to plan #{plan}", level: :test
  command_code_id = 'M0002'
  command_name = 'setPlan'
  message = nil

  message = @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'timeplan', 'v' => plan.to_s}
  ]

  log_confirmation "intention to switch to plan #{plan}" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'securityCode','v' => security_code, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'timeplan','v' => plan.to_s, 'age' => age }
    ])
  end
end

# Note the spelling error 'traficsituation'. This should be fixed in future version
def set_traffic_situation ts
  status = 'True'
  security_code = SECRETS['security_codes'][2]

  @site.log "Switching to traffic situation #{ts}", level: :test
  command_code_id = 'M0003'
  command_name = 'setTrafficSituation'
  message = nil

  message = @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'traficsituation', 'v' => ts}
  ]

  log_confirmation "intention to switch to traffic situation #{ts}" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'securityCode','v' => security_code, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'traficsituation','v' => ts, 'age' => age }
    ])
  end
end

def set_restart
  status = 'True'
  security_code = SECRETS['security_codes'][2]

  @site.log "Restarting traffic controller", level: :test
  command_code_id = 'M0004'
  command_name = 'setRestart'
  @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code}
  ]

  # if the controller restarts immediately, we will not receive a command response,
  # so do not expect this
end

def set_emergency_route status, route
  security_code = SECRETS['security_codes'][2]

  @site.log "Set emergency route", level: :test
  command_code_id = 'M0005'
  command_name = 'setEmergency'
  message = nil

  message = @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'emergencyroute', 'v' => route}
  ]

  log_confirmation "intention to switch to emergency route #{route}" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'securityCode','v' => security_code, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'emergencyroute','v' => route, 'age' => age }
    ])
  end
end

def set_input status, input
  security_code = SECRETS['security_codes'][2]

  @site.log "Set input", level: :test
  command_code_id = 'M0006'
  command_name = 'setInput'
  message = nil

  message = @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'input', 'v' => input}
  ]

  log_confirmation "intention to set input #{input}" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'securityCode','v' => security_code, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'input','v' => input, 'age' => age }
    ])
  end
end

def set_fixed_time status
  security_code = SECRETS['security_codes'][2]

  @site.log "Switching to fixed time #{status}", level: :test
  command_code_id = 'M0007'
  command_name = 'setFixedTime'
  message = nil

  message = @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code}
  ]

  log_confirmation"intention to switch to fixed time #{status}" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'securityCode','v' => security_code, 'age' => age }
    ])
  end
end

def force_detector_logic component, status, value='True'
  security_code = SECRETS['security_codes'][2]

  @site.log "Force detector logic", level: :test
  command_code_id = 'M0008'
  command_name = 'setForceDetectorLogic'
  message = nil

  message = @site.send_command component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'mode', 'v' => value}
  ]

  log_confirmation "intention to force detector logic" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'securityCode','v' => security_code, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'mode','v' => value, 'age' => age }
    ])
  end
end

def set_signal_start status
  security_code = SECRETS['security_codes'][2]
  indx = 0
  component = COMPONENT_CONFIG['signal_group'].keys[indx]

  @site.log "Start of signal group. Orders a signal group to green.", level: :test
  command_code_id = 'M0010'
  command_name = 'setStart'
  message = nil

  message = @site.send_command component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code}
  ]

  log_confirmation "intention to set start of signal group." do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'securityCode','v' => security_code, 'age' => age }
    ])
  end
end

def set_signal_stop status
  security_code = SECRETS['security_codes'][2]
  indx = 0
  component = COMPONENT_CONFIG['signal_group'].keys[indx]

  @site.log "Stop of signal group. Orders a signal group to red.", level: :test
  command_code_id = 'M0011'
  command_name = 'setStop'
  message = nil

  message = @site.send_command component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code}
  ]

  log_confirmation "intention to set stop of signal group" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'securityCode','v' => security_code, 'age' => age }
    ])
  end
end

def set_signal_start_or_stop status
  security_code = SECRETS['security_codes'][2]

  @site.log "Request start or stop of a series of signal groups", level: :test
  command_code_id = 'M0012'
  command_name = 'setStart'
  message = nil

  message = @site.send_command component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code}
  ]

  log_confirmation "intention to request start or stop of a series of signal groups" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'securityCode','v' => security_code, 'age' => age }
    ])
  end
end


def set_series_of_inputs status
  security_code = SECRETS['security_codes'][2]

  @site.log "Activate a series of inputs", level: :test
  command_code_id = 'M0013'
  command_name = 'setInput'
  message = nil

  message = @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code}
  ]

  log_confirmation "intention to activate a series of inputs #{status}" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      {'cCI' => command_code_id, 'n' => 'status', 'v' => status, 'age' => age},
      {'cCI' => command_code_id, 'n' => 'securityCode', 'v' => security_code, 'age' => age}
    ])
  end
end

def set_dynamic_bands status, plan
  security_code = SECRETS['security_codes'][2]

  @site.log "Set dynamic bands", level: :test
  command_code_id = 'M0014'
  command_name = 'setCommands'
  message = nil

  message = @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'plan', 'v' => plan},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code}
  ]

  log_confirmation "intention to set dynamic bands #{plan}" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      {'cCI' => command_code_id, 'n' => 'status', 'v' => status, 'age' => age},
      {'cCI' => command_code_id, 'n' => 'plan', 'v' => plan, 'age' => age},
      {'cCI' => command_code_id, 'n' => 'securityCode', 'v' => security_code, 'age' => age}
    ])
  end
end

def set_offset status, plan
  security_code = SECRETS['security_codes'][2]

  @site.log "Set offset", level: :test
  command_code_id = 'M0015'
  command_name = 'setOffset'
  message = nil

  message = @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'plan', 'v' => plan},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code}
  ]

  log_confirmation "intention to set offset #{plan}" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    expect(response.attributes['rvs']).to eq([
      {'cCI' => command_code_id, 'n' => 'status', 'v' => status},
      {'cCI' => command_code_id, 'n' => 'plan', 'v' => plan},
      {'cCI' => command_code_id, 'n' => 'securityCode', 'v' => security_code}
    ])
  end
end

def set_week_table status
  security_code = SECRETS['security_codes'][2]

  @site.log "Set week table", level: :test
  command_code_id = 'M0016'
  command_name = 'setWeekTable'
  message = nil

  message = @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code}
  ]

  log_confirmation "intention to set week table #{status}" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    expect(response.attributes['rvs']).to eq([
      {'cCI' => command_code_id, 'n' => 'status', 'v' => status},
      {'cCI' => command_code_id, 'n' => 'securityCode', 'v' => security_code}
    ])
  end
end

def set_time_table status
  security_code = SECRETS['security_codes'][2]

  @site.log "Set time table", level: :test
  command_code_id = 'M0017'
  command_name = 'setTimeTable'
  message = nil

  message = @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code}
  ]

  log_confirmation "intention to set time table #{status}" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    expect(response.attributes['rvs']).to eq([
      {'cCI' => command_code_id, 'n' => 'status', 'v' => status},
      {'cCI' => command_code_id, 'n' => 'securityCode', 'v' => security_code}
    ])
  end
end

def set_cycle_time status, plan
  security_code = SECRETS['security_codes'][2]

  @site.log "Set cycle time", level: :test
  command_code_id = 'M0018'
  command_name = 'setCycleTable'
  message = nil

  message = @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'plan', 'v' => plan},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code}
  ]

  log_confirmation "intention to set cycle table #{plan}" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    expect(response.attributes['rvs']).to eq([
      {'cCI' => command_code_id, 'n' => 'status', 'v' => status},
      {'cCI' => command_code_id, 'n' => 'plan', 'v' => plan},
      {'cCI' => command_code_id, 'n' => 'securityCode', 'v' => security_code}
    ])
  end
end

def force_input status, input, inputValue
  security_code = SECRETS['security_codes'][2]

  @site.log "Force input", level: :test
  command_code_id = 'M0019'
  command_name = 'setInput'
  message = nil

  message = @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'input', 'v' => input},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'inputValue', 'v' => inputValue},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code}
  ]

  log_confirmation "intention to force input #{inputValue}" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    expect(response.attributes['rvs']).to eq([
      {'cCI' => command_code_id, 'n' => 'status', 'v' => status},
      {'cCI' => command_code_id, 'n' => 'input', 'v' => input},
      {'cCI' => command_code_id, 'n' => 'inputValue', 'v' => inputValue},
      {'cCI' => command_code_id, 'n' => 'securityCode', 'v' => security_code}
    ])
  end
end

def force_output status, output, outputValue
  security_code = SECRETS['security_codes'][2]

  @site.log "Force output", level: :test
  command_code_id = 'M0020'
  command_name = 'setOutput'
  message = nil

  message = @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'output', 'v' => output},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'outputValue', 'v' => outputValue},
    {'cCI' => command_code_id, 'cO' => 'setInput', 'n' => 'securityCode', 'v' => security_code}
  ]

  log_confirmation "intention to force output #{outputValue}" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    expect(response.attributes['rvs']).to eq([
      {'cCI' => command_code_id, 'n' => 'status', 'v' => status},
      {'cCI' => command_code_id, 'n' => 'output', 'v' => output},
      {'cCI' => command_code_id, 'n' => 'outputValue', 'v' => outputValue},
      {'cCI' => command_code_id, 'n' => 'securityCode', 'v' => security_code}
    ])
  end
end

def set_cycle_time status
  security_code = SECRETS['security_codes'][2]

  @site.log "Set trigger level sensitivity for loop detector", level: :test
  command_code_id = 'M0021'
  command_name = 'setLevel'
  message = nil

  message = @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => 'setInput', 'n' => 'securityCode', 'v' => security_code}
  ]

  log_confirmation "intention to set trigger level sensitivity for loop detector #{status}" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    expect(response.attributes['rvs']).to eq([
      {'cCI' => command_code_id, 'n' => 'status', 'v' => status},
      {'cCI' => command_code_id, 'n' => 'securityCode', 'v' => security_code}
    ])
  end
end

def set_security_code status
  security_code = SECRETS['security_codes'][2]

  @site.log "Set security code", level: :test
  command_code_id = 'M0103'
  command_name = 'setSecurityCode'
  message = nil

  message = @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'oldSecurityCode', 'v' => security_code},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'newSecurityCode', 'v' => security_code}
  ]

  log_confirmation "intention to set security code" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = "recent"
    expect(response.attributes['rvs']).to eq([
      {'age' => age, 'cCI' => command_code_id, 'n' => 'status', 'v' => status},
      {'age' => age, 'cCI' => command_code_id, 'n' => 'oldSecurityCode', 'v' => security_code},
      {'age' => age, 'cCI' => command_code_id, 'n' => 'newSecurityCode', 'v' => security_code}
    ])
  end
end

def set_date status
  security_code = SECRETS['security_codes'][2]

  @site.log "Set date", level: :test
  command_code_id = 'M0104'
  command_name = 'setDate'
  year = 2020
  month = "09"
  day = 29
  hour = 17
  minute = 29
  second = 51
  message = nil

  message = @site.send_command @component, [ {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'year', 'v' => year},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'month', 'v' => month},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'day', 'v' => day},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'hour', 'v' => hour},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'minute', 'v' => minute},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'second', 'v' => second}
  ]

  log_confirmation "intention to set date" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      {'cCI' => command_code_id, 'n' => 'securityCode', 'v' => security_code},
      {'cCI' => command_code_id, 'n' => 'year', 'v' => year},
      {'cCI' => command_code_id, 'n' => 'month', 'v' => month},
      {'cCI' => command_code_id, 'n' => 'day', 'v' => day},
      {'cCI' => command_code_id, 'n' => 'hour', 'v' => hour},
      {'cCI' => command_code_id, 'n' => 'minute', 'v' => minute},
      {'cCI' => command_code_id, 'n' => 'second', 'v' => second}
    ])
  end
end

def wrong_security_code
  indx = 0
  component = COMPONENT_CONFIG['detector_logic'].keys[indx]
  status = 'True'
  value = 'True'
  security_code = SECRETS['security_codes'][3]

  @site.log "Force detector logic", level: :test
  command_code_id = 'M0008'
  command_name = 'setForceDetectorLogic'
  message = nil

  message = @site.send_command component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'mode', 'v' => value}
  ]

  log_confirmation "intention to force detector logic with wrong security code" do
    response = nil
    expect do
      response = @site.wait_for_command_response message: message, component: component, timeout: RSMP_CONFIG['command_timeout']
    end.to raise_error

    expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(component)
    put(response)
  end
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

def verify_status status_list:, description:
  log_confirmation description do
    subscribe status_list
    status_list.each do |item|
      response = nil
      expect do
        response = @site.wait_for_status_update component: @component, sCI: item['sCI'],
          n: item['n'], q:'recent', s:item['s'], timeout: RSMP_CONFIG['status_timeout']
      end.to_not raise_error, "Did not receive status #{item.inspect}"
    end
    unsubscribe_from_all
  end
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

def switch_input input
  indx = input - 1
  set_input 'True',input.to_s
  verify_status(**{
    description:"activate input #{input}",
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

RSpec.describe 'RSMP site commands' do  
  it 'M0001 set yellow flash' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_yellow_flash
      switch_normal_control
    end
  end

  it 'M0001 set dark mode' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_dark_mode
      switch_normal_control
    end
  end

  it 'M0002 set time plan' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      SITE_CONFIG['plans'].each { |plan| switch_plan plan }
    end
  end

  it 'M0003 set traffic situation' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      SITE_CONFIG['traffic_situations'].each { |ts| switch_traffic_situation ts.to_s }
    end
  end

  it 'M0004 restart' do |example|
    TestSite.log_test_header example
    TestSite.isolated do |task,supervisor,site|
      prepare task, site
      #if ask_user site, "Going to restart controller. Press enter when ready or 's' to skip:"
      set_restart
      expect { site.wait_for_state :stopped, RSMP_CONFIG['shutdown_timeout'] }.to_not raise_error
    end
    # NOTE
    # when a remote site closes the connection, our site proxy object will stop.
    # when the site reconnects, a new site proxy object will be created.
    # this means we can't wait for the old site to become ready
    # it also means we need a new TestSite.
    TestSite.isolated do |task,supervisor,site|
      prepare task, site
      expect { site.wait_for_state :ready, RSMP_CONFIG['ready_timeout'] }.to_not raise_error
      wait_normal_control
    end
  end

  it 'M0005 activate emergency route' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      SITE_CONFIG['emergency_routes'].each { |route| switch_emergency_route route.to_s }
    end
  end

  it 'M0006 activate input' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      unsubscribe_from_all
      SITE_CONFIG['inputs'].each { |input| switch_input input }
    end
  end

  it 'M0007 set fixed time', important: true do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_fixed_time 'True'
      switch_fixed_time 'False'
    end
  end

  it 'M0008 activate detector logic', important: true do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_detector_logic 
    end
  end

  it 'M0010 start signal group', important: true do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_signal_start 'True'
    end
  end

  it 'M0011 stop signal group', important: true do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_signal_stop 'True'
    end
  end

  it 'M0012 request start/stop of a series of signal groups', important: true do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_signal_start_or_stop '5,4134,65;5,11'
    end
  end

  it 'M0013 activate a series of inputs' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      status = "5,4134,65;511"
      prepare task, site
      set_series_of_inputs status
    end
  end
  
  it 'M0014 set command table' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      plan = "1"
      status = "10,10"
      prepare task, site
      set_dynamic_bands status, plan
    end
  end

  it 'M0015 set offset' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      plan = 1
      status = 255
      prepare task, site
      set_offset status, plan
    end
  end

  it 'M0016 set week table' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      status = "0-1,6-2"
      prepare task, site
      set_week_table status
    end
  end

  it 'M0017 set time table' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      status = "12-1-12-59,1-0-23-12"
      prepare task, site
      set_time_table status
    end
  end

  it 'M0018 set cycle time' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      status = 5
      plan = 0
      prepare task, site
      set_cycle_time status, plan
    end
  end

  it 'M0019 force input' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      status = 'False'
      input = 1
      inputValue = 'True'
      prepare task, site
      force_input status, input, inputValue
    end
  end

  it 'M0020 force output' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      status = 'False'
      output = 1
      outputValue = 'True'
      prepare task, site
      force_output status, output, outputValue
    end
  end

  it 'M0021 set trigger sensitivity' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      status = 'False'
      output = 1
      outputValue = 'True'
      prepare task, site
      force_output status
    end
  end

  it 'M0103 set security code', foobar: true do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_security_code '-Level1'
    end
  end

  it 'M0104 set date' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_date
    end
  end

  it 'Send the wrong security code' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      wrong_security_code 
    end
  end
end
