module CommandHelpers
  def send_command_and_confirm parent_task, command_list, message, component=@component
    log_confirmation message do
      result = @site.wait_for_command_responses parent_task, {
        component: component,
        command_list: command_list,
        timeout: SUPERVISOR_CONFIG['command_response_timeout']
      } do |m_id|
        @site.send_command component, command_list, m_id: m_id
      end
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

  def set_signal_start status
    @site.log "Start of signal group. Orders a signal group to green.", level: :test
    command_list = build_command_list :M0010, :setStart, {
      securityCode: SECRETS['security_codes'][2],
      status: status
    }
    indx = 0
    component = COMPONENT_CONFIG['signal_group'].keys[indx]
    send_command_and_confirm @task, command_list, "intention to set start of signal group #{indx}.", component
  end

  def set_signal_stop status
    @site.log "Stop of signal group. Orders a signal group to red.", level: :test
    command_list = build_command_list :M0011, :setStop, {
      securityCode: SECRETS['security_codes'][2],
      status: status
    }
    indx = 0
    component = COMPONENT_CONFIG['signal_group'].keys[indx]
    send_command_and_confirm @task, command_list, "intention to set stop of signal group #{indx}.", component
  end

  def set_signal_start_or_stop status
    @site.log "Request start or stop of a series of signal groups", level: :test
    command_list = build_command_list :M0012, :setStart, {
      securityCode: SECRETS['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list,
      "intention to request start or stop of a series of signal groups"
  end

  def set_plan plan
    @site.log "Switching to traffic situation #{plan}", level: :test
    command_list = build_command_list :M0002, :setPlan, {
      securityCode: SECRETS['security_codes'][2],
      timeplan: plan
    }
    send_command_and_confirm @task, command_list, "intention to switch to plan #{plan}"
  end

  def set_traffic_situation ts
    @site.log "Switching to traffic situation #{ts}", level: :test
    command_list = build_command_list :M0003, :setTrafficSituation, {
      securityCode: SECRETS['security_codes'][2],
      traficsituation: ts   # misspell 'traficsituation'is in the rsmp spec

    }
    send_command_and_confirm @task, command_list, "intention to switch to traffic situation #{ts}"
  end

  def set_functional_position status
    @site.log "Switching to #{status}", level: :test
    command_list = build_command_list :M0001, :setValue, {
      securityCode: SECRETS['security_codes'][2],
      status: status,
      timeout: 0,
      intersection: 0 
    }
    send_command_and_confirm @task, command_list, "intention to switch to #{status}"
  end

  def set_fixed_time status
    @site.log "Switching to fixed time #{status}", level: :test
    command_list = build_command_list :M0007, :setFixedTime, {
      securityCode: SECRETS['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to switch to fixed time #{status}"
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
    send_command_and_confirm @task, command_list, "intention to switch to emergency route #{route}"
  end

  def set_input status, input
    @site.log "Set input #{input}", level: :test
    command_list = build_command_list :M0006, :setInput, {
      securityCode: SECRETS['security_codes'][2],
      input: input
    }
    send_command_and_confirm @task, command_list, "intention to set input #{input}"
  end

  def force_detector_logic component, status, mode='True'
    @site.log "Force detector logic", level: :test
    command_list = build_command_list :M0008, :setForceDetectorLogic, {
      securityCode: SECRETS['security_codes'][2],
      status: status,
      mode: mode
    }
    send_command_and_confirm @task, command_list, "intention to force detector logic #{status} to #{mode}", component
  end

  def switch_plan plan
    set_plan plan.to_s
    verify_status(@task,
      "switch to plan #{plan}",
      [{'sCI'=>'S0014','n'=>'status','s'=>plan.to_s}]
    )
  end

  def switch_traffic_situation ts
    set_traffic_situation ts
    verify_status(@task,
      "switch to traffic situation #{ts}",
      [{'sCI'=>'S0015','n'=>'status','s'=>ts}]
    )
  end

  def switch_yellow_flash
    set_functional_position 'YellowFlash'
    verify_status(@task,
      "switch to yellow flash",
      [{'sCI'=>'S0011','n'=>'status','s'=>/^True(,True)*$/}]
    )
  end

  def switch_dark_mode
    set_functional_position 'Dark'
    verify_status(@task,
      "switch to dark mode",
      [{'sCI'=>'S0007','n'=>'status','s'=>/^False(,False)*$/}]
    )
  end

  def set_series_of_inputs status
    @site.log "Activate a series of inputs", level: :test
    command_list = build_command_list :M0013, :setInput, {
      securityCode: SECRETS['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to activate a series of inputs #{status}"
  end

  def set_dynamic_bands status, plan
    @site.log "Set dynamic bands", level: :test
    command_list = build_command_list :M0014, :setCommands, {
      securityCode: SECRETS['security_codes'][2],
      status: status,
      plan: plan
    }
    send_command_and_confirm @task, command_list, "intention to set dynamic bands #{status} for plan #{plan}"
  end

  def set_offset status, plan
    @site.log "Set dynamic bands", level: :test
    command_list = build_command_list :M0015, :setOffset, {
      securityCode: SECRETS['security_codes'][2],
      status: status,
      plan: plan
    }
    send_command_and_confirm @task, command_list, "intention to set offset #{plan}"
  end

  def set_week_table status
    @site.log "Set week table", level: :test
    command_list = build_command_list :M0016, :setWeekTable, {
      securityCode: SECRETS['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to set week table #{status}"
  end

  def set_time_table status
    @site.log "Set time table", level: :test
    command_list = build_command_list :M0017, :setTimeTable, {
      securityCode: SECRETS['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to set time table #{status}"
  end

  def set_cycle_time status, plan
    @site.log "Set cycle time", level: :test
    command_list = build_command_list :M0018, :setCycleTime, {
      securityCode: SECRETS['security_codes'][2],
      status: status,
      plan: plan
    }
    send_command_and_confirm @task, command_list, "intention to set cycle table #{plan}"
  end

  def force_input status, input, value
    @site.log "Force input", level: :test
    command_list = build_command_list :M0019, :setInput, {
      securityCode: SECRETS['security_codes'][2],
      status: status,
      input: input,
      inputValue: value
    }
    send_command_and_confirm @task, command_list,  "intention to force input #{input} to #{value}"
  end

  def force_output status, output, value
    @site.log "Force output", level: :test
    command_list = build_command_list :M0020, :setOutput, {
      securityCode: SECRETS['security_codes'][2],
      status: status,
      output: output,
      outputValue: value
    }
    send_command_and_confirm @task, command_list, "intention to force output #{output} to #{value}"
  end

  def set_trigger_level status
    @site.log "Set trigger level sensitivity for loop detector", level: :test
    command_list = build_command_list :M0021, :setLevel, {
      securityCode: SECRETS['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to set trigger level sensitivity for loop detector #{status}"
  end

  def set_security_code level
    status = "Level#{level}"
    @site.log "Set security code", level: :test
    command_list = build_command_list :M0103, :setSecurityCode, {
      oldSecurityCode: SECRETS['security_codes'][level],
      newSecurityCode: SECRETS['security_codes'][level],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to set security code"
  end

  def set_date
    @site.log "Set date", level: :test
    command_list = build_command_list :M0104, :setDate, {
      securityCode: SECRETS['security_codes'][1],
      year: 2020,
      month: '09',
      day: 29,
      hour: 17,
      minute: 29,
      second: 51
    }
    send_command_and_confirm @task, command_list, "intention to set date"
  end

  def wrong_security_code
    @site.log "Force detector logic", level: :test
    command_list = build_command_list :M0008, :setForceDetectorLogic, {
      securityCode: '1111',
      status: 'True',
      mode: 'True'
    }
    component = COMPONENT_CONFIG['detector_logic'].keys[0]
    expect {
      send_command_and_confirm @task, command_list, "rejection of wrong security code", component
    }.to raise_error(RSMP::MessageRejected)
  end

  def wait_normal_control
    # Wait for:
    # 'switched on' to be true (dark mode false)
    #  yellow flash status to be false
    # for startup mode to be false
    verify_status(@task,
      "dark mode off, yellow flash off, start-up mode off",
      [
        {'sCI'=>'S0007','n'=>'status','s'=>/^True(,True)*$/},
        {'sCI'=>'S0011','n'=>'status','s'=>/^False(,False)*$/},
        {'sCI'=>'S0005','n'=>'status','s'=>'False'}
      ]
    )
  end

  def switch_normal_control
    set_functional_position 'NormalControl'
    wait_normal_control
  end

  def switch_fixed_time status
    set_fixed_time status
    verify_status(@task,
      "switch to fixed time #{status}",
      [{'sCI'=>'S0009','n'=>'status','s'=>/^#{status}(,#{status})*$/}]
    )
  end

  def switch_emergency_route route
    set_emergency_route 'True',route
    verify_status(@task,
      "activate emergency route",
      [
        {'sCI'=>'S0006','n'=>'status','s'=>'True'},
        {'sCI'=>'S0006','n'=>'emergencystage','s'=>route}
      ]
    )

    set_emergency_route 'False',route
    verify_status(@task,
      "deactivate emergency route",
      [{'sCI'=>'S0006','n'=>'status','s'=>'False'}]
    )
  end

  def switch_input
    indx = 0
    set_input 'True',indx.to_s
    verify_status(@task,
      "activate input #{indx}",
      [{'sCI'=>'S0003','n'=>'inputstatus','s'=>/^.{#{indx}}1/}]
    )

    set_input 'False',indx.to_s
    verify_status(@task,
      "deactivate input #{indx}",
      [{'sCI'=>'S0003','n'=>'inputstatus','s'=>/^.{#{indx}}0/}]
    )
  end

  def switch_detector_logic
    indx = 0
    component = COMPONENT_CONFIG['detector_logic'].keys[indx]

    force_detector_logic component, 'True', 'True'
    @component = MAIN_COMPONENT
    verify_status(@task,
      "activate detector logic #{component}",
      [{'sCI'=>'S0002','n'=>'detectorlogicstatus','s'=>/^.{#{indx}}1/}]
    )
    

    force_detector_logic component, 'False'
    @component = MAIN_COMPONENT
    verify_status(@task,
      "deactivate detector logic #{component}",
      [{'sCI'=>'S0002','n'=>'detectorlogicstatus','s'=>/^.{#{indx}}0/}]
    )
  end

  def prepare task, site
    @component = MAIN_COMPONENT
    @task = task
    @site = site
  end
end
