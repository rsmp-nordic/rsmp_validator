module CommandHelpers
  def send_command_and_confirm parent_task, command_list, message, component=Validator.config['main_component']
    result = nil
    log_confirmation message do
      result = @site.send_command component, command_list, collect: {
          timeout: Validator.config['timeouts']['command_response']
        }
    end
    return *result   # use splat '*' operator
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
    require_security_codes
    @site.log "Start of signal group. Orders a signal group to green.", level: :test
    command_list = build_command_list :M0010, :setStart, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    indx = 0
    component = Validator.config['components']['signal_group'].keys[indx]
    send_command_and_confirm @task, command_list, "intention to set start of signal group #{indx}.", component
  end

  def set_signal_stop status
    require_security_codes
    @site.log "Stop of signal group. Orders a signal group to red.", level: :test
    command_list = build_command_list :M0011, :setStop, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    indx = 0
    component = Validator.config['components']['signal_group'].keys[indx]
    send_command_and_confirm @task, command_list, "intention to set stop of signal group #{indx}.", component
  end

  def set_signal_start_or_stop status
    @site.log "Request start or stop of a series of signal groups", level: :test
    command_list = build_command_list :M0012, :setStart, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list,
      "intention to request start or stop of a series of signal groups"
  end

  def set_plan plan
    require_security_codes
    @site.log "Switching to plan #{plan}", level: :test
    command_list = build_command_list :M0002, :setPlan, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: 'True',     # true = use plan nr in commone, false = use time table
      timeplan: plan
    }
    send_command_and_confirm @task, command_list, "intention to switch to plan #{plan}"
  end

  def set_traffic_situation ts
    require_security_codes
    @site.log "Switching to traffic situation #{ts}", level: :test
    command_list = build_command_list :M0003, :setTrafficSituation, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      traficsituation: ts   # misspell 'traficsituation'is in the rsmp spec

    }
    send_command_and_confirm @task, command_list, "intention to switch to traffic situation #{ts}"
  end

  def set_functional_position status
    require_security_codes
    @site.log "Switching to #{status}", level: :test
    command_list = build_command_list :M0001, :setValue, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      timeout: 0,
      intersection: 0 
    }
    send_command_and_confirm @task, command_list, "intention to switch to #{status}"
  end

  def set_fixed_time status
    require_security_codes
    @site.log "Switching to fixed time #{status}", level: :test
    command_list = build_command_list :M0007, :setFixedTime, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to switch to fixed time #{status}"
  end

  def set_restart
    require_security_codes
    @site.log "Restarting traffic controller", level: :test
    command_list = build_command_list :M0004, :setRestart, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: 'True'
    }
    @site.send_command Validator.config['main_component'], command_list
    # if the controller restarts immediately, we will not receive a command response,
    # so do not expect this
  end

  def set_emergency_route route
    require_security_codes
    @site.log "Set emergency route #{route}", level: :test
    command_list = build_command_list :M0005, :setEmergency, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: 'True',
      emergencyroute: route
    }
    send_command_and_confirm @task, command_list, "intention to switch to emergency route #{route}"
  end

  def disable_emergency_route
    require_security_codes
    @site.log "Disable emergency route", level: :test
    command_list = build_command_list :M0005, :setEmergency, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: 'False'
    }
    send_command_and_confirm @task, command_list, "intention to switch emergency off"
  end

  def set_input status, input
    require_security_codes
    @site.log "Set input #{input}", level: :test
    command_list = build_command_list :M0006, :setInput, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      input: input
    }
    send_command_and_confirm @task, command_list, "intention to set input #{input}"
  end

  def force_detector_logic component, status, mode='True'
    require_security_codes
    @site.log "Force detector logic", level: :test
    command_list = build_command_list :M0008, :setForceDetectorLogic, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      mode: mode
    }
    send_command_and_confirm @task, command_list, "intention to force detector logic #{status} to #{mode}", component
  end

  def switch_plan plan
    set_plan plan.to_s
    wait_for_status(@task,
      "switch to plan #{plan}",
      [{'sCI'=>'S0014','n'=>'status','s'=>plan.to_s}]
    )
  end

  def switch_traffic_situation ts
    set_traffic_situation ts
    wait_for_status(@task,
      "switch to traffic situation #{ts}",
      [{'sCI'=>'S0015','n'=>'status','s'=>ts}]
    )
  end

  def switch_yellow_flash
    set_functional_position 'YellowFlash'
    wait_for_status(@task,
      "switch to yellow flash",
      [{'sCI'=>'S0011','n'=>'status','s'=>/^True(,True)*$/}]
    )
  end

  def switch_dark_mode
    set_functional_position 'Dark'
    wait_for_status(@task,
      "switch to dark mode",
      [{'sCI'=>'S0007','n'=>'status','s'=>/^False(,False)*$/}]
    )
  end

  def set_series_of_inputs status
    require_security_codes
    @site.log "Activate a series of inputs", level: :test
    command_list = build_command_list :M0013, :setInput, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to activate a series of inputs #{status}"
  end

  def set_dynamic_bands status, plan
    require_security_codes
    @site.log "Set dynamic bands", level: :test
    command_list = build_command_list :M0014, :setCommands, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      plan: plan
    }
    send_command_and_confirm @task, command_list, "intention to set dynamic bands #{status} for plan #{plan}"
  end

  def set_offset status, plan
    require_security_codes
    @site.log "Set dynamic bands", level: :test
    command_list = build_command_list :M0015, :setOffset, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      plan: plan
    }
    send_command_and_confirm @task, command_list, "intention to set offset #{plan}"
  end

  def set_week_table status
    require_security_codes
    @site.log "Set week table", level: :test
    command_list = build_command_list :M0016, :setWeekTable, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to set week table #{status}"
  end

  def set_time_table status
    require_security_codes
    @site.log "Set time table", level: :test
    command_list = build_command_list :M0017, :setTimeTable, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to set time table #{status}"
  end

  def set_cycle_time status, plan
    require_security_codes
    @site.log "Set cycle time", level: :test
    command_list = build_command_list :M0018, :setCycleTime, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      plan: plan
    }
    send_command_and_confirm @task, command_list, "intention to set cycle table #{plan}"
  end

  def force_input status, input, value
    require_security_codes
    @site.log "Force input", level: :test
    command_list = build_command_list :M0019, :setInput, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      input: input,
      inputValue: value
    }
    send_command_and_confirm @task, command_list,  "intention to force input #{input} to #{value}"
  end

  def force_output status, output, value
    require_security_codes
    @site.log "Force output", level: :test
    command_list = build_command_list :M0020, :setOutput, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      output: output,
      outputValue: value
    }
    send_command_and_confirm @task, command_list, "intention to force output #{output} to #{value}"
  end

  def set_trigger_level status
    require_security_codes
    @site.log "Set trigger level sensitivity for loop detector", level: :test
    command_list = build_command_list :M0021, :setLevel, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to set trigger level sensitivity for loop detector #{status}"
  end

  def set_security_code level
    require_security_codes
    status = "Level#{level}"
    @site.log "Set security code", level: :test
    command_list = build_command_list :M0103, :setSecurityCode, {
      oldSecurityCode: Validator.config['secrets']['security_codes'][level],
      newSecurityCode: Validator.config['secrets']['security_codes'][level],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to set security code"
  end

  def require_security_codes
    unless Validator.config.dig 'secrets', 'security_codes' 
      skip "Skipping test: Security codes are not configured"
    end
  end

  def require_scripts
    skip "Skipping test: Scripts are not configured" unless Validator.config['scripts']
    skip "Skipping test: Script to activate alarm is not configured" unless Validator.config.dig 'scripts', 'activate_alarm'
    skip "Skipping test: Script to deactivate alarm is not configured" unless Validator.config.dig 'scripts','deactivate_alarm'
  end

  def set_date date
    require_security_codes
    @site.log "Set date to #{date}", level: :test
    command_list = build_command_list :M0104, :setDate, {
      securityCode: Validator.config['secrets']['security_codes'][1],
      year: date.year,
      month: date.month,
      day: date.day,
      hour: date.hour,
      minute: date.min,
      second: date.sec
    }
    send_command_and_confirm @task, command_list, "intention to set date"
  end

  def reset_date
    require_security_codes
    @site.log "Reset date", level: :test
    now = Time.now.utc
    command_list = build_command_list :M0104, :setDate, {
      securityCode: Validator.config['secrets']['security_codes'][1],
      year: now.year,
      month: now.month,
      day: now.day,
      hour: now.hour,
      minute: now.min,
      second: now.sec
    }
    send_command_and_confirm @task, command_list, "intention to set date"
  end

  def with_date_set date, &block
    request, response = set_date date
    yield request,response
  ensure
    reset_date
  end


  def wrong_security_code
    @site.log "Try to force detector logic with wrong security code", level: :test
    command_list = build_command_list :M0008, :setForceDetectorLogic, {
      securityCode: '1111',
      status: 'True',
      mode: 'True'
    }
    component = Validator.config['components']['detector_logic'].keys[0]
    expect {
      send_command_and_confirm @task, command_list, "rejection of wrong security code", component
    }.to raise_error(RSMP::MessageRejected)
  end

  def wait_normal_control
    # Wait for:
    # 'switched on' to be true (dark mode false)
    #  yellow flash status to be false
    # for startup mode to be false
    wait_for_status(@task,
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
    wait_for_status(@task,
      "switch to fixed time #{status}",
      [{'sCI'=>'S0009','n'=>'status','s'=>/^#{status}(,#{status})*$/}]
    )
  end

  def switch_emergency_route route
    set_emergency_route route
    wait_for_status(@task,
      "activate emergency route",
      [
        {'sCI'=>'S0006','n'=>'status','s'=>'True'},
        {'sCI'=>'S0006','n'=>'emergencystage','s'=>route}
      ]
    )

    disable_emergency_route
    wait_for_status(@task,
      "deactivate emergency route",
      [{'sCI'=>'S0006','n'=>'status','s'=>'False'}]
    )
  end

  def switch_input indx
    set_input 'True',indx.to_s
    wait_for_status(@task,
      "activate input #{indx}",
      [{'sCI'=>'S0003','n'=>'inputstatus','s'=>/^.{#{indx-1}}1/}] # index is 1-based, convert to 0-based fo regex
    )

    set_input 'False',indx.to_s
    wait_for_status(@task,
      "deactivate input #{indx}",
      [{'sCI'=>'S0003','n'=>'inputstatus','s'=>/^.{#{indx-1}}0/}]
    )
  end

  def switch_detector_logic
    indx = 0
    component = Validator.config['components']['detector_logic'].keys[indx]

    force_detector_logic component, 'True', 'True'
    Validator.config['main_component'] = Validator.config['main_component']
    wait_for_status(@task,
      "activate detector logic #{component}",
      [{'sCI'=>'S0002','n'=>'detectorlogicstatus','s'=>/^.{#{indx}}1/}]
    )
    

    force_detector_logic component, 'False'
    Validator.config['main_component'] = Validator.config['main_component']
    wait_for_status(@task,
      "deactivate detector logic #{component}",
      [{'sCI'=>'S0002','n'=>'detectorlogicstatus','s'=>/^.{#{indx}}0/}]
    )
  end

  def prepare task, site
    @task = task
    @site = site
  end
end
