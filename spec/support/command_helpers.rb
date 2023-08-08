module Validator::CommandHelpers
  def send_command_and_confirm parent_task, command_list, message, component=Validator.config['main_component']
    result = nil
    log message
    @site.send_command component, command_list, collect!: {
      timeout: Validator.config['timeouts']['command_response']
    }
  end

  # Build a RSMP command value list from a hash
  def build_command_list command_code_id, command_name, values
    values.compact.to_a.map do |n,v|
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
    command_list = build_command_list :M0010, :setStart, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: 'True'
    }
    indx = 0
    component = Validator.config['components']['signal_group'].keys[indx]
    send_command_and_confirm @task, command_list, "Order signal group #{indx} to green", component
  end

  # Order a signal group to red
  def set_signal_stop
    require_security_codes
    command_list = build_command_list :M0011, :setStop, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: 'True'
    }
    indx = 0
    component = Validator.config['components']['signal_group'].keys[indx]
    send_command_and_confirm @task, command_list, "Order signal group #{indx} to red", component
  end

  # Request series of signal groups to start/stop
  def set_signal_start_or_stop status
    command_list = build_command_list :M0012, :setStart, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "Request series of signal groups to #{status}"
  end

  # Switch signal plan
  def set_plan plan
    require_security_codes
    command_list = build_command_list :M0002, :setPlan, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: 'True',     # true = use plan nr in commone, false = use time table
      timeplan: plan
    }
    send_command_and_confirm @task, command_list, "Switchto plan #{plan}"
  end

  def switch_traffic_situation ts
    set_traffic_situation ts
    wait_for_status(@task,
      "traffic situation #{ts}",
      [{'sCI'=>'S0015','n'=>'status','s'=>ts}]
    )
  end

  # Set traffic situation
  def set_traffic_situation ts
    require_security_codes
    command_list = build_command_list :M0003, :setTrafficSituation, {
      status: 'True',
      securityCode: Validator.config['secrets']['security_codes'][2],
      traficsituation: ts   # note: the spec misspells 'traficsituation'

    }
    send_command_and_confirm @task, command_list, "Switch to traffic situation #{ts}"
  end

  # Unset traffic situation (switch to automatic)
  def unset_traffic_situation
    require_security_codes
    command_list = build_command_list :M0003, :setTrafficSituation, {
      status: 'False',
      securityCode: Validator.config['secrets']['security_codes'][2],
      traficsituation: '0'   # note: the spec misspells 'traficsituation'

    }
    send_command_and_confirm @task, command_list, "Switch to automaatic traffic situation"
  end

  # Set functional position
  def set_functional_position status, timeout_minutes:0
    require_security_codes
    command_list = build_command_list :M0001, :setValue, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      timeout: timeout_minutes,
      intersection: 0
    }
    send_command_and_confirm @task, command_list, "Switch to functional position #{status}"
  end

  def set_fixed_time status
    require_security_codes
    command_list = build_command_list :M0007, :setFixedTime, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "Switch to fixed time #{status}"
  end

  def set_restart
    require_security_codes
    log "Restarting traffic controller"
    command_list = build_command_list :M0004, :setRestart, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: 'True'
    }
    @site.send_command Validator.config['main_component'], command_list
    # if the controller restarts immediately, we will not receive a command response,
    # so do not expect it
  end

  def set_emergency_route route
    require_security_codes
    command_list = build_command_list :M0005, :setEmergency, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: 'True',
      emergencyroute: route
    }
    send_command_and_confirm @task, command_list, "Set emergency route #{route}"
  end

  def disable_emergency_route route
    require_security_codes
    command_list = build_command_list :M0005, :setEmergency, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: 'False',
      emergencyroute: route
    }
    send_command_and_confirm @task, command_list, "Disable emergency route #{route}"
  end

  def set_input status, input
    require_security_codes
    command_list = build_command_list :M0006, :setInput, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      input: input
    }
    send_command_and_confirm @task, command_list, "Set input #{input} to #{status}"
  end

  def force_detector_logic component, status:'True', mode:'True'
    require_security_codes
    command_list = build_command_list :M0008, :setForceDetectorLogic, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      mode: mode
    }
    send_command_and_confirm @task, command_list, "Force detector logic #{component} to #{mode}", component
  end

  def switch_plan plan
    set_plan plan.to_s
    wait_for_status(@task,
      "plan #{plan} to be active",
      [{'sCI'=>'S0014','n'=>'status','s'=>plan.to_s}]
    )
  end

  def switch_yellow_flash timeout_minutes: 0
    set_functional_position 'YellowFlash', timeout_minutes: timeout_minutes
    wait_for_status(@task,
      "yellow flash",
      [{'sCI'=>'S0011','n'=>'status','s'=>/^True(,True)*$/}]
    )
  end

  def switch_dark_mode
    set_functional_position 'Dark'
    wait_for_status(@task,
      "dark mode",
      [{'sCI'=>'S0007','n'=>'status','s'=>/^False(,False)*$/}]
    )
  end

  def set_series_of_inputs status
    require_security_codes
    command_list = build_command_list :M0013, :setInput, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "Set a series of inputs using #{status}"
  end

  def set_dynamic_bands plan, status
    require_security_codes
    command_list = build_command_list :M0014, :setCommands, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      plan: plan
    }
    send_command_and_confirm @task, command_list, "Set dynamic bands to #{status} for plan #{plan}"
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
    command_list = build_command_list :M0015, :setOffset, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      plan: plan
    }
    send_command_and_confirm @task, command_list, "Set offset for plan #{plan} to #{status}"
  end

  def set_week_table status
    require_security_codes
    command_list = build_command_list :M0016, :setWeekTable, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "Set week table to #{status}"
  end

  def set_day_table status
    require_security_codes
    command_list = build_command_list :M0017, :setTimeTable, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "Set time table to #{status}"
  end

  def set_cycle_time status, plan
    require_security_codes
    command_list = build_command_list :M0018, :setCycleTime, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      plan: plan
    }
    send_command_and_confirm @task, command_list, "Set cycle time to #{plan}"
  end

  def force_input input:, status:'True', value: 'True', validate:true
    require_security_codes
    if status == 'True'
      str = "Force input #{input} to #{value}"
      wait_str = "input #{input} to be forced to #{value}"
    else
      str =  "Release input #{input}"
      wait_str = "input #{input} to be released"
    end
    command_list = build_command_list :M0019, :setInput, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      input: input,
      inputValue: value
    }
    send_command_and_confirm @task, command_list, str

    if status == 'True'
      input_status_str = value == 'True' ? '1' : '0'
      wait_for_status(@task, wait_str, [
        {'sCI'=>'S0029','n'=>'status','s'=>/^.{#{input - 1}}1/},
        {'sCI'=>'S0003','n'=>'inputstatus','s'=>/^.{#{input - 1}}#{input_status_str}/}
      ])
    else
      wait_for_status(@task, wait_str, [
        {'sCI'=>'S0029','n'=>'status','s'=>/^.{#{input - 1}}0/}
      ])
    end

  end

  def force_output output:, status:, value:'True', validate:true
    require_security_codes
    command_list = build_command_list :M0020, :setOutput, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status,
      output: output,
      outputValue: value
    }
    send_command_and_confirm @task, command_list, "Force output #{output} to #{value}"
  end

  def set_trigger_level status
    require_security_codes
    command_list = build_command_list :M0021, :setLevel, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "Set trigger level sensitivity for loop detector to #{status}"
  end

  def set_timeout_for_dynamic_bands status
    require_security_codes
    command_list = build_command_list :M0023, :setTimeout, {
      securityCode: Validator.config['secrets']['security_codes'][2],
      status: status
    }
    send_command_and_confirm @task, command_list, "Set timeout for dynamic bands to #{status}"
  end

  def set_security_code level
    require_security_codes
    status = "Level#{level}"
    command_list = build_command_list :M0103, :setSecurityCode, {
      oldSecurityCode: Validator.config['secrets']['security_codes'][level],
      newSecurityCode: Validator.config['secrets']['security_codes'][level],
      status: status
    }
    send_command_and_confirm @task, command_list, "Set security code for level #{level}"
  end

  def require_security_codes
    unless Validator.config.dig 'secrets', 'security_codes'
      skip "Security codes are not configured"
    end
  end

  # Run a block with ana alarm acticated, then deactive the alarm
  # The device must be programmed to activate an alarm when a specific
  # input is acticated, and the mapping must be configured in the test config.
  def with_alarm_activated task, site, alarm_code_id, initial_deactivation: true
    action = Validator.config.dig('alarms', alarm_code_id)
    skip "alarm #{alarm_code_id} is not configured" unless action
    input_nr = action['activation_input']
    skip "alarm #{alarm_code_id} has no activation input configured" unless input_nr
    component_id = action['component'] || Validator.config['main_component']
    if initial_deactivation
      force_input_and_confirm input: input_nr, value: 'False'
    end
    state = false
    begin
      if RSMP::Proxy.version_meets_requirement? site.core_version, '>=3.2'
        # from core 3.2 all enum matching must be match exactly
        alarm_specialization = /Issue/
        alarm_active = /Active/
        alarm_inactive = /inActive/
      else
        # before 3.2 match is done case-insensitively
        alarm_specialization = /issue/i
        alarm_active = /active/i
        alarm_inactive = /inactive/i
      end

      collect_task = task.async do  # run the collector in an async task
        collector = RSMP::AlarmCollector.new( site,
          num: 1,
          query: { 
            'cId' => component_id,
            'aCId' =>  alarm_code_id,
            'aSp' =>  alarm_specialization,
            'aS' => alarm_active
          },
          timeout: Validator.config['timeouts']['alarm']
        )
        collector.collect!
        collector.messages.first
      end
      force_input_and_confirm input: input_nr, value: 'True'
      state = true
      yield collect_task.wait, component_id

      collect_task = task.async do  # run the collector in an async task
        collector = RSMP::AlarmCollector.new( site,
          num: 1,
          query: {
            'cId' => component_id,
            'aCId' =>  alarm_code_id,
            'aSp' =>  /Issue/i,
            'aS' => alarm_inactive
          },
          timeout: Validator.config['timeouts']['alarm']
        )
        collector.collect!
        collector.messages.first
      end
      force_input_and_confirm input: input_nr, value: 'False'
      state = false
      return collect_task.wait, component_id
    ensure
      force_input_and_confirm input: input_nr, value: 'False' if state == true
    end
  end

  def force_input_and_confirm(input:, value:)
    force_input status: 'True', input: input, value: value
    digit = (value == 'True' ? '1' : '0')
    wait_for_status(@task,
      "input #{input} to be #{value}",
      [{'sCI'=>'S0003','n'=>'inputstatus','s'=>/^.{#{input-1}}#{digit}/}] # index is 1-based, convert to 0-based fo regex
    )
  end

  def set_clock clock
    require_security_codes
    command_list = build_command_list :M0104, :setDate, {
      securityCode: Validator.config['secrets']['security_codes'][1],
      year: clock.year,
      month: clock.month,
      day: clock.day,
      hour: clock.hour,
      minute: clock.min,
      second: clock.sec
    }
    send_command_and_confirm @task, command_list, "Set clock to #{clock}"
  end

  def reset_clock
    require_security_codes
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
    send_command_and_confirm @task, command_list, "Reset clock to #{now}"
  end

  def with_clock_set clock, &block
    result = set_clock clock
    yield result
  ensure
    reset_clock
  end


  def wrong_security_code
    log "Try to force detector logic with wrong security code"
    command_list = build_command_list :M0008, :setForceDetectorLogic, {
      securityCode: '1111',
      status: 'True',
      mode: 'True'
    }
    component = Validator.config['components']['detector_logic'].keys[0]
    result = @site.send_command component, command_list, collect!: {
      timeout: Validator.config['timeouts']['command_response']
    }
  end

  def wait_normal_control timeout: Validator.config['timeouts']['startup_sequence']
    wait_for_status(@task,
      "normal control on, yellow flash off, startup mode off",
      [
        {'sCI'=>'S0007','n'=>'status','s'=>/^True(,True)*$/},     # normal control on (=dark mode off)
        {'sCI'=>'S0011','n'=>'status','s'=>/^False(,False)*$/},   # yellow flash off
        {'sCI'=>'S0005','n'=>'status','s'=>'False'}               # startup mode off
      ],
      timeout: timeout
    )
  end

  def verify_startup_sequence &block
    status_list = [{'sCI'=>'S0001','n'=>'signalgroupstatus'}]
    subscribe_list = convert_status_list(status_list).map { |item| item.merge 'uRt'=>0.to_s }
    subscribe_list.map! { |item| item.merge!('sOc' => 'False') } if use_sOc?(@site)

    unsubscribe_list = convert_status_list(status_list)
    component = Validator.config['main_component']
    timeout = Validator.config['timeouts']['startup_sequence']
    collector = RSMP::StatusCollector.new @site, status_list, timeout: timeout
    sequencer = Validator::StatusHelpers::SequenceHelper.new Validator.config['startup_sequence']
    states = nil

    collector_task = @task.async do
      log "Verifying startup sequence"
      collector.collect do |message,item|   # listen for status messages
        next unless item
        states = item['s']
        #p states
        status  = sequencer.check states      # check sequences
        if status == :ok
          log "Startup sequence #{states}: OK"
          if sequencer.done?             # if all groups reached end?
            collector.complete           # then end collection
          else
            false                        # reject item, ie. continue collecting
          end
        else
          log "Startup sequence #{states}: Fail"
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
      log "Startup sequence verified"
    when :timeout
      raise "Startup sequence '#{sequencer.sequence}' didn't complete in #{timeout}s, reached #{sequencer.latest}, #{sequencer.num_started} started, #{sequencer.num_done} done"
    when :cancelled
      raise "Startup sequence '#{sequencer.sequence}' not followed: #{collector.error}"
    end

    wait_for_status(@task,"control mode to be startup", [{'sCI'=>'S0020','n'=>'controlmode','s'=>'control'}])
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
      "fixed time to be #{status}",
      [{'sCI'=>'S0009','n'=>'status','s'=>/^#{status}(,#{status})*$/}]
    )
  end

  def switch_emergency_route route
    set_emergency_route route
    wait_for_status(@task,
      "emergency route #{route} to be enabled",
      [
        {'sCI'=>'S0006','n'=>'status','s'=>'True'},
        {'sCI'=>'S0006','n'=>'emergencystage','s'=>route}
      ]
    )

    disable_emergency_route route
    wait_for_status(@task,
      "emergency route #{route} to be disabled",
      [
        {'sCI'=>'S0006','n'=>'status','s'=>'False'},
        {'sCI'=>'S0006','n'=>'emergencystage','s'=>route}
      ]
    )
  end

  def switch_input indx
    set_input 'True',indx.to_s
    wait_for_status(@task,
      "input #{indx} to be True",
      [{'sCI'=>'S0003','n'=>'inputstatus','s'=>/^.{#{indx-1}}1/}] # index is 1-based, convert to 0-based fo regex
    )

    set_input 'False',indx.to_s
    wait_for_status(@task,
      "input #{indx} to be False",
      [{'sCI'=>'S0003','n'=>'inputstatus','s'=>/^.{#{indx-1}}0/}]
    )
  end

  def prepare task, site
    @task = task
    @site = site
  end
end
