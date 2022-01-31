module Validator::CommandHelpers
  def send_command_and_confirm parent_task, command_list, message, component=Validator.config['main_component']
    result = nil
    log_confirmation message do
      result = @site.send_command component, command_list, collect!: {
          timeout: Validator.config['timeouts']['command_response']
        }
    end
    result
  end

  # Build a RSMP command value list from a hash
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

  # Order a signal group to green
  def set_signal_start
    require_security_codes
    Validator.log "Order signal group to green", level: :test
    command_list = build_command_list :M0010, :setStart, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: 'True'
    }
    indx = 0
    component = Validator.config['components']['signal_group'].keys[indx]
    send_command_and_confirm @task, command_list, "intention to start signal group #{indx}.", component
  end

  # Order a signal group to red
  def set_signal_stop
    require_security_codes
    Validator.log "Order signal group to red", level: :test
    command_list = build_command_list :M0011, :setStop, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: 'True'
    }
    indx = 0
    component = Validator.config['components']['signal_group'].keys[indx]
    send_command_and_confirm @task, command_list, "intention to stop signal group #{indx}.", component
  end

  # Request series of signal groups to start/stop
  def set_signal_start_or_stop status
    Validator.log "Request series of signal groups to start/stop", level: :test
    command_list = build_command_list :M0012, :setStart, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list,
      "intention to request start/stop of a series of signal groups"
  end

  # Switch signal plan
  def set_plan plan
    require_security_codes
    Validator.log "Switching to plan #{plan}", level: :test
    command_list = build_command_list :M0002, :setPlan, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: 'True',     # true = use plan nr in commone, false = use time table
      timeplan: plan
    }
    send_command_and_confirm @task, command_list, "intention to switch to plan #{plan}"
  end

  # Set traffic situation
  def set_traffic_situation ts
    require_security_codes
    Validator.log "Switching to traffic situation #{ts}", level: :test
    command_list = build_command_list :M0003, :setTrafficSituation, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      traficsituation: ts   # misspell 'traficsituation'is in the rsmp spec

    }
    send_command_and_confirm @task, command_list, "intention to switch to traffic situation #{ts}"
  end

  # Set functional position
  def set_functional_position status
    require_security_codes
    Validator.log "Switching to #{status}", level: :test
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
    Validator.log "Switching to fixed time #{status}", level: :test
    command_list = build_command_list :M0007, :setFixedTime, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to switch to fixed time #{status}"
  end

  def set_restart
    require_security_codes
    Validator.log "Restarting traffic controller", level: :test
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
    Validator.log "Set emergency route #{route}", level: :test
    command_list = build_command_list :M0005, :setEmergency, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: 'True',
      emergencyroute: route
    }
    send_command_and_confirm @task, command_list, "intention to switch to emergency route #{route}"
  end

  def disable_emergency_route
    require_security_codes
    Validator.log "Disable emergency route", level: :test
    command_list = build_command_list :M0005, :setEmergency, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: 'False'
    }
    send_command_and_confirm @task, command_list, "intention to switch emergency off"
  end

  def set_input status, input
    require_security_codes
    Validator.log "Set input #{input}", level: :test
    command_list = build_command_list :M0006, :setInput, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      input: input
    }
    send_command_and_confirm @task, command_list, "intention to set input #{input}"
  end

  def force_detector_logic component, status:'True', mode:'True'
    require_security_codes
    Validator.log "Force detector logic", level: :test
    command_list = build_command_list :M0008, :setForceDetectorLogic, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      mode: mode
    }
    send_command_and_confirm @task, command_list, "intention to force detector logic to #{mode}", component
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
    Validator.log "Activate a series of inputs", level: :test
    command_list = build_command_list :M0013, :setInput, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to activate a series of inputs #{status}"
  end

  def set_dynamic_bands plan, status
    require_security_codes
    Validator.log "Set dynamic bands", level: :test
    command_list = build_command_list :M0014, :setCommands, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      plan: plan
    }
    send_command_and_confirm @task, command_list, "intention to set dynamic bands #{status} for plan #{plan}"
  end

  def get_dynamic_bands plan, band
    Validator.log "Get dynamic bands", level: :test
    status_list = { S0023: [:status] }
    result = @site.request_status Validator.config['main_component'], convert_status_list(status_list), collect!: {
      timeout: Validator.config['timeouts']['status_update']
    }
    collector = result[:collector]
    collector.queries.first.got['s'].split(',').each do |item|
      some_plan, some_band, value = *item.split('-')
      return value.to_i if some_plan.to_i == plan.to_i && some_band.to_i == band.to_i
    end
    nil
  end


  def set_offset status, plan
    require_security_codes
    Validator.log "Set dynamic bands", level: :test
    command_list = build_command_list :M0015, :setOffset, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      plan: plan
    }
    send_command_and_confirm @task, command_list, "intention to set offset #{plan}"
  end

  def set_week_table status
    require_security_codes
    Validator.log "Set week table", level: :test
    command_list = build_command_list :M0016, :setWeekTable, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to set week table #{status}"
  end

  def set_day_table status
    require_security_codes
    Validator.log "Set time table", level: :test
    command_list = build_command_list :M0017, :setTimeTable, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to set time table #{status}"
  end

  def set_cycle_time status, plan
    require_security_codes
    Validator.log "Set cycle time", level: :test
    command_list = build_command_list :M0018, :setCycleTime, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      plan: plan
    }
    send_command_and_confirm @task, command_list, "intention to set cycle table #{plan}"
  end

  def force_input status, input, value
    require_security_codes
    Validator.log "Force input", level: :test
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
    Validator.log "Force output", level: :test
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
    Validator.log "Set trigger level sensitivity for loop detector", level: :test
    command_list = build_command_list :M0021, :setLevel, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to set trigger level sensitivity for loop detector #{status}"
  end

  def set_security_code level
    require_security_codes
    status = "Level#{level}"
    Validator.log "Set security code", level: :test
    command_list = build_command_list :M0103, :setSecurityCode, {
      oldSecurityCode: Validator.config['secrets']['security_codes'][level],
      newSecurityCode: Validator.config['secrets']['security_codes'][level],
      status: status
    }
    send_command_and_confirm @task, command_list, "intention to set security code"
  end

  def require_security_codes
    unless Validator.config.dig 'secrets', 'security_codes' 
      skip "Security codes are not configured"
    end
  end

  def run_script key
    path = Validator.config.dig('scripts',key)
    raise "No Script configured for '#{key}'" unless path
    system(path) if path
  end

  def skip_unless_scripts_are_configured
    unless Validator.config['scripts'] && Validator.config['scripts'].any?
      skip "Skipping because scripts are not configured"
    end
  end

  def with_alarm_activated
    run_script 'activate_alarm'
    yield
  ensure
    run_script 'deactivate_alarm'
  end

  def set_clock clock
    require_security_codes
    Validator.log "Setting clock to #{clock}", level: :test
    command_list = build_command_list :M0104, :setDate, {
      securityCode: Validator.config['secrets']['security_codes'][1],
      year: clock.year,
      month: clock.month,
      day: clock.day,
      hour: clock.hour,
      minute: clock.min,
      second: clock.sec
    }
    send_command_and_confirm @task, command_list, "intention to set clock"
  end

  def reset_clock
    require_security_codes
    Validator.log "Resetting clock", level: :test
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
    send_command_and_confirm @task, command_list, "intention to set clock"
  end

  def with_clock_set clock, &block
    result = set_clock clock
    yield result
  ensure
    reset_clock
  end


  def wrong_security_code
    Validator.log "Try to force detector logic with wrong security code", level: :test
    command_list = build_command_list :M0008, :setForceDetectorLogic, {
      securityCode: '1111',
      status: 'True',
      mode: 'True'
    }
    component = Validator.config['components']['detector_logic'].keys[0]
    result = send_command_and_confirm @task, command_list, "M0008 with wrong security code", component
    Validator.log "Command rejected as expected", level: :test
  end

  def wait_normal_control
    wait_for_status(@task,
      "normal control on, yellow flash off, startup mode off",
      [
        {'sCI'=>'S0007','n'=>'status','s'=>/^True(,True)*$/},     # normal control on (=dark mode off)
        {'sCI'=>'S0011','n'=>'status','s'=>/^False(,False)*$/},   # yellow flash off
        {'sCI'=>'S0005','n'=>'status','s'=>'False'}               # startup mode off
      ],
      timeout: Validator.config['timeouts']['startup_sequence'].size + 2
    )
  end

  def verify_startup_sequence &block
    status_list = [{'sCI'=>'S0001','n'=>'signalgroupstatus'}]
    subscribe_list = convert_status_list(status_list).map { |item| item.merge 'uRt'=>0.to_s }
    unsubscribe_list = convert_status_list(status_list)
    component = Validator.config['main_component']
    timeout = Validator.config['timeouts']['startup_sequence']
    collector = RSMP::StatusCollector.new @site, status_list, timeout: timeout
    sequencer = Validator::StatusHelpers::SequenceHelper.new Validator.config['startup_sequence']
    states = nil

    collector_task = @task.async do
      @site.log "Verifying startup sequence"
      collector.collect do |message,item|   # listen for status messages
        next unless item
        states = item['s']
        #p states
        status  = sequencer.check states      # check sequences
        if status == :ok
          @site.log "Startup sequence #{states}: OK", level: :test
          if sequencer.done?             # if all groups reached end?
            collector.complete           # then end collection
          else
            false                        # reject item, ie. continue collecting
          end
        else
          @site.log "Startup sequence #{states}: Fail", level: :test
          collector.cancel status        # if sequence was incorrect then cancel collection
        end
      end
    end

    # let block take other actions, like restarting the site, change control mode, etc.
    yield

    # subscribe, so we start getting status udates
    @site.subscribe_to_status component, subscribe_list


    case collector_task.wait  # wait for the collector to complete
    when :ok
      @site.log "Startup sequence verified", level: :test
    when :timeout
      raise "Startup sequence '#{sequencer.sequence}' didn't complete in #{timeout}s, reached #{sequencer.latest}, #{sequencer.num_started} started, #{sequencer.num_done} done"
    when :cancelled
      raise "Startup sequence '#{sequencer.sequence}' not followed: #{collector.error}"
    end

    wait_for_status(@task,"controlmode startup", [{'sCI'=>'S0020','n'=>'controlmode','s'=>'control'}])
  ensure
    @site.unsubscribe_to_status component, unsubscribe_list  # unsubscribe
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

    force_detector_logic component, mode:'True'
    Validator.config['main_component'] = Validator.config['main_component']
    wait_for_status(@task,
      "activate detector logic #{component}",
      [{'sCI'=>'S0002','n'=>'detectorlogicstatus','s'=>/^.{#{indx}}1/}]
    )
    

    force_detector_logic component, mode:'False'
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
