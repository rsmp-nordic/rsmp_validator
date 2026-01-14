# frozen_string_literal: true

module Validator
  module CommandHelpers
    # Send an RSMP command and wait for confirmation response
    def send_command_and_confirm(_parent_task, command_list, message,
                                 component = Validator.get_config('main_component'))
      log message
      @site.send_command component, command_list, collect!: {
        timeout: Validator.get_config('timeouts', 'command_response')
      }
    end

    # Build a RSMP command value list from a hash
    # @param command_code_id [Symbol] the command code identifier (e.g. :M0001)
    # @param command_name [Symbol] the command name (e.g. :setValue)
    # @param values [Hash] key-value pairs for command parameters
    # @return [Array] formatted command list for RSMP
    def build_command_list(command_code_id, command_name, values)
      values.compact.to_a.map do |n, v|
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
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: 'True'
      }
      indx = 0
      component = Validator.get_config('components', 'signal_group').keys[indx]
      send_command_and_confirm @task, command_list, "Order signal group #{indx} to green", component
    end

    # Order a signal group to red
    def set_signal_stop
      require_security_codes
      command_list = build_command_list :M0011, :setStop, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: 'True'
      }
      indx = 0
      component = Validator.get_config('components', 'signal_group').keys[indx]
      send_command_and_confirm @task, command_list, "Order signal group #{indx} to red", component
    end

    # Switch signal plan
    def apply_plan(plan)
      require_security_codes
      command_list = build_command_list :M0002, :setPlan, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: 'True', # true = use plan nr in commone, false = use time table
        timeplan: plan
      }
      send_command_and_confirm @task, command_list, "Switch to plan #{plan}"
    end

    # Switch to traffic situation and wait for confirmation via status
    def switch_traffic_situation(traffic_situation)
      apply_traffic_situation traffic_situation
      wait_for_status(
        "traffic situation #{traffic_situation}",
        [{ 'sCI' => 'S0015', 'n' => 'status', 's' => traffic_situation }]
      )
    end

    # Set traffic situation
    def apply_traffic_situation(traffic_situation)
      require_security_codes
      command_list = build_command_list :M0003, :setTrafficSituation, {
        status: 'True',
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        traficsituation: traffic_situation # NOTE: the spec misspells 'traficsituation'

      }
      send_command_and_confirm @task, command_list, "Switch to traffic situation #{traffic_situation}"
    end

    # Unset traffic situation (switch to automatic)
    # The spec does not state what traficsituation to use when unsetting,
    # here we're using 1. (Allowed range is 1-255)
    def unset_traffic_situation
      require_security_codes
      command_list = build_command_list :M0003, :setTrafficSituation, {
        status: 'False',
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        traficsituation: '1' # NOTE: the spec misspells 'traficsituation'

      }
      send_command_and_confirm @task, command_list, 'Switch to automatic traffic situation'
    end

    # Set functional position
    def set_functional_position(status, timeout_minutes: 0)
      require_security_codes
      command_list = build_command_list :M0001, :setValue, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: status,
        timeout: timeout_minutes,
        intersection: 0
      }
      send_command_and_confirm @task, command_list, "Switch to functional position #{status}"
    end

    def apply_fixed_time(status)
      require_security_codes
      command_list = build_command_list :M0007, :setFixedTime, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: status
      }
      send_command_and_confirm @task, command_list, "Switch to fixed time #{status}"
    end

    def set_emergency_route(route, state)
      if state
        enable_emergency_route route
      else
        disable_emergency_route route
      end
    end

    def enable_emergency_route(route)
      require_security_codes
      command_list = build_command_list :M0005, :setEmergency, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: 'True',
        emergencyroute: route
      }
      send_command_and_confirm @task, command_list, "Enable emergency route #{route}"
    end

    def disable_emergency_route(route)
      require_security_codes
      command_list = build_command_list :M0005, :setEmergency, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: 'False',
        emergencyroute: route
      }
      send_command_and_confirm @task, command_list, "Disable emergency route #{route}"
    end

    def set_input(status, input)
      require_security_codes
      command_list = build_command_list :M0006, :setInput, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: status,
        input: input
      }
      send_command_and_confirm @task, command_list, "Set input #{input} to #{status}"
    end

    def force_detector_logic(component, status: 'True', mode: 'True')
      require_security_codes
      command_list = build_command_list :M0008, :setForceDetectorLogic, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: status,
        mode: mode
      }
      send_command_and_confirm @task, command_list, "Force detector logic #{component} to #{mode}", component
    end

    def switch_plan(plan)
      apply_plan plan.to_s
      wait_for_status(
        "plan #{plan} to be active",
        [{ 'sCI' => 'S0014', 'n' => 'status', 's' => plan.to_s }]
      )
    end

    def switch_yellow_flash(timeout_minutes: 0)
      set_functional_position 'YellowFlash', timeout_minutes: timeout_minutes
      wait_for_status(
        'yellow flash',
        [{ 'sCI' => 'S0011', 'n' => 'status', 's' => /^True(,True)*$/ }]
      )
    end

    def switch_dark_mode
      set_functional_position 'Dark'
      wait_for_status(
        'dark mode',
        [{ 'sCI' => 'S0007', 'n' => 'status', 's' => /^False(,False)*$/ }]
      )
    end

    def apply_series_of_inputs(status)
      require_security_codes
      command_list = build_command_list :M0013, :setInput, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: status
      }
      send_command_and_confirm @task, command_list, "Set a series of inputs using #{status}"
    end

    def set_dynamic_bands(plan, status)
      require_security_codes
      command_list = build_command_list :M0014, :setCommands, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: status,
        plan: plan
      }
      send_command_and_confirm @task, command_list, "Set dynamic bands to #{status} for plan #{plan}"
    end

    def get_dynamic_bands(plan, band)
      Validator.log 'Get dynamic bands', level: :test
      status_list = { S0023: [:status] }
      result = @site.request_status(
        Validator.get_config('main_component'),
        convert_status_list(status_list),
        collect!: {
          timeout: Validator.get_config('timeouts', 'status_update', default: 0)
        }
      )
      collector = result[:collector]
      collector.matchers.first.got['s'].split(',').each do |item|
        some_plan, some_band, value = *item.split('-')
        return value.to_i if some_plan.to_i == plan.to_i && some_band.to_i == band.to_i
      end
      nil
    end

    def set_offset(status, plan)
      require_security_codes
      command_list = build_command_list :M0015, :setOffset, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: status,
        plan: plan
      }
      send_command_and_confirm @task, command_list, "Set offset for plan #{plan} to #{status}"
    end

    def apply_week_table(status)
      require_security_codes
      command_list = build_command_list :M0016, :setWeekTable, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: status
      }
      send_command_and_confirm @task, command_list, "Set week table to #{status}"
    end

    def apply_day_table(status)
      require_security_codes
      command_list = build_command_list :M0017, :setTimeTable, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: status
      }
      send_command_and_confirm @task, command_list, "Set time table to #{status}"
    end

    def set_cycle_time(plan, cycle_time, description = "Set cycle time to #{cycle_time} for plan #{plan}")
      require_security_codes
      command_list = build_command_list :M0018, :setCycleTime, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: cycle_time,
        plan: plan
      }
      send_command_and_confirm @task, command_list, description
    end

    def with_cycle_time_extended(site, extension = 5, &block)
      # read current plan
      plan = read_current_plan(site)

      # read initial cycle times
      times = read_cycle_times(site)
      time = times[plan]

      expect(time).not_to be_nil, 'Site returned empty cycle times list'

      # change cycle tme
      time_extended = time + extension
      need_to_reset = true
      set_cycle_time plan, time_extended, "Extend cycle time to #{time_extended} for plan #{plan}"

      # read updated cycle times
      times = read_cycle_times(site, 'updated cycle times')
      time_extended_actual = times[plan]
      expect(time_extended_actual).to eq(time_extended)

      block.yield
    ensure
      if need_to_reset
        log 'Reset cycle time'
        set_cycle_time plan, time
      end
    end

    def force_input(input:, status: 'True', value: 'True', validate: true)
      require_security_codes
      if status == 'True'
        str = "Force input #{input} to #{value}"
        wait_str = "input #{input} to be forced to #{value}"
      else
        str = "Release input #{input}"
        wait_str = "input #{input} to be released"
      end
      command_list = build_command_list :M0019, :setInput, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: status,
        input: input,
        inputValue: value
      }
      send_command_and_confirm @task, command_list, str

      return unless validate

      if status == 'True'
        input_status_str = value == 'True' ? '1' : '0'
        wait_for_status(
          wait_str,
          [
            { 'sCI' => 'S0029', 'n' => 'status', 's' => /^.{#{input - 1}}1/ },
            { 'sCI' => 'S0003', 'n' => 'inputstatus', 's' => /^.{#{input - 1}}#{input_status_str}/ }
          ]
        )
      else
        wait_for_status(
          wait_str,
          [
            { 'sCI' => 'S0029', 'n' => 'status', 's' => /^.{#{input - 1}}0/ }
          ]
        )
      end
    end

    def force_output(output:, status:, value: 'True', validate: true)
      require_security_codes
      command_list = build_command_list :M0020, :setOutput, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: status,
        output: output,
        outputValue: value
      }
      send_command_and_confirm @task, command_list, "Force output #{output} to #{value}"

      validate
    end

    def apply_trigger_level(status)
      require_security_codes
      command_list = build_command_list :M0021, :setLevel, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: status
      }
      send_command_and_confirm @task, command_list, "Set trigger level sensitivity for loop detector to #{status}"
    end

    def apply_timeout_for_dynamic_bands(status)
      require_security_codes
      command_list = build_command_list :M0023, :setTimeout, {
        securityCode: Validator.get_config('secrets', 'security_codes', 2),
        status: status
      }
      send_command_and_confirm @task, command_list, "Set timeout for dynamic bands to #{status}"
    end

    def apply_security_code(level)
      require_security_codes
      status = "Level#{level}"
      command_list = build_command_list :M0103, :setSecurityCode, {
        oldSecurityCode: Validator.get_config('secrets', 'security_codes', level),
        newSecurityCode: Validator.get_config('secrets', 'security_codes', level),
        status: status
      }
      send_command_and_confirm @task, command_list, "Set security code for level #{level}"
    end

    # Check if security codes are configured, skip test if not available
    def require_security_codes
      return if Validator.config.dig 'secrets', 'security_codes'

      skip 'Security codes are not configured'
    end

    # Run a block with an alarm acticated, then deactive the alarm
    # The device must be programmed to activate an alarm when a specific
    # input is acticated, and the mapping must be configured in the test config.
    def with_alarm_activated(task, site, alarm_code_id, initial_deactivation: true)
      input_nr, component_id = find_alarm_programming(alarm_code_id)
      component_id ||= Validator.get_config('main_component')
      force_input_and_confirm input: input_nr, value: 'False' if initial_deactivation
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
          collector = RSMP::AlarmCollector.new(site,
                                               num: 1,
                                               matcher: {
                                                 'cId' => component_id,
                                                 'aCId' => alarm_code_id,
                                                 'aSp' => alarm_specialization,
                                                 'aS' => alarm_active
                                               },
                                               timeout: Validator.get_config('timeouts', 'alarm'))
          collector.collect!
          collector.messages.first
        end
        force_input_and_confirm input: input_nr, value: 'True'
        state = true
        yield collect_task.wait, component_id

        collect_task = task.async do  # run the collector in an async task
          collector = RSMP::AlarmCollector.new(site,
                                               num: 1,
                                               matcher: {
                                                 'cId' => component_id,
                                                 'aCId' => alarm_code_id,
                                                 'aSp' => /Issue/i,
                                                 'aS' => alarm_inactive
                                               },
                                               timeout: Validator.get_config('timeouts', 'alarm'))
          collector.collect!
          collector.messages.first
        end
        force_input_and_confirm input: input_nr, value: 'False'
        state = false
        [collect_task.wait, component_id]
      ensure
        force_input_and_confirm input: input_nr, value: 'False' if state == true
      end
    end

    def force_input_and_confirm(input:, value:)
      force_input status: 'True', input: input, value: value
      digit = (value == 'True' ? '1' : '0')

      # Index is 1-based, convert to 0-based for regex
      wait_for_status(
        "input #{input} to be #{value}",
        [
          { 'sCI' => 'S0003', 'n' => 'inputstatus', 's' => /^.{#{input - 1}}#{digit}/ }
        ]
      )
    end

    def apply_clock(clock)
      require_security_codes
      command_list = build_command_list :M0104, :setDate, {
        securityCode: Validator.get_config('secrets', 'security_codes', 1),
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
        securityCode: Validator.get_config('secrets', 'security_codes', 1),
        year: now.year,
        month: now.month,
        day: now.day,
        hour: now.hour,
        minute: now.min,
        second: now.sec
      }
      send_command_and_confirm @task, command_list, "Reset clock to #{now}"
    end

    def stop_sending_watchdogs(site)
      # monkey-patch the site object by redefining
      # the send_watchdog method to do nothing
      def site.send_watchdog(now = nil); end
    end

    def with_clock_set(site, clock)
      result = apply_clock clock
      site.clear_alarm_timestamps
      yield result
    ensure
      reset_clock
    end

    def wrong_security_code
      log 'Try to force detector logic with wrong security code'
      command_list = build_command_list :M0008, :setForceDetectorLogic, {
        securityCode: '1111',
        status: 'True',
        mode: 'True'
      }
      component = Validator.get_config('components', 'detector_logic').keys[0]
      @site.send_command component, command_list, collect!: {
        timeout: Validator.get_config('timeouts', 'command_response')
      }
    end

    def wait_normal_control(timeout: Validator.get_config('timeouts', 'startup_sequence'))
      wait_for_status(
        'normal control on, yellow flash off, startup mode off',
        [
          {
            'sCI' => 'S0007',
            'n' => 'status',
            's' => /^True(,True)*$/ # normal control on (=dark mode off)
          },
          { 'sCI' => 'S0011', 'n' => 'status', 's' => /^False(,False)*$/ }, # yellow flash off
          { 'sCI' => 'S0005', 'n' => 'status', 's' => 'False' } # startup mode off
        ],
        timeout: timeout
      )
    end

    def verify_startup_sequence
      status_list = [{ 'sCI' => 'S0001', 'n' => 'signalgroupstatus' }]
      subscribe_list = convert_status_list(status_list).map { |item| item.merge 'uRt' => 0.to_s }
      subscribe_list.map! { |item| item.merge!('sOc' => true) } if use_soc?(@site)

      unsubscribe_list = convert_status_list(status_list)
      component = Validator.get_config('main_component')
      timeout = Validator.get_config('timeouts', 'startup_sequence')
      collector = RSMP::StatusCollector.new @site, status_list, timeout: timeout
      sequencer = Validator::StatusHelpers::SignalGroupSequenceHelper.new Validator.get_config('startup_sequence')
      states = nil

      collector_task = @task.async do
        log 'Verifying startup sequence'
        collector.collect do |_message, item| # listen for status messages
          next unless item

          states = item['s']
          handle_startup_sequence_item(states, sequencer, collector)
        end
      end

      # let block take other actions, like activating yellow flash, change control mode, etc.
      yield

      # subscribe, so we start getting status udates
      @site.subscribe_to_status component, subscribe_list

      handle_startup_sequence_result(collector_task.wait, sequencer, collector, timeout)

      wait_for_status(
        'control mode to be startup',
        [{ 'sCI' => 'S0020', 'n' => 'controlmode', 's' => 'control' }]
      )
    ensure
      @site.unsubscribe_to_status component, unsubscribe_list # unsubscribe
    end

    def handle_startup_sequence_item(states, sequencer, collector)
      status = sequencer.check(states)

      if status == :ok
        log "Startup sequence #{states}: OK"
        return collector.complete if sequencer.done?

        return false
      end

      log "Startup sequence #{states}: Fail"
      collector.cancel status
    end

    def handle_startup_sequence_result(result, sequencer, collector, timeout)
      case result
      when :ok
        log 'Startup sequence verified'
      when :timeout
        raise(
          "Startup sequence '#{sequencer.sequence}' didn't complete in #{timeout}s, " \
          "reached #{sequencer.latest}, #{sequencer.num_started} started, " \
          "#{sequencer.num_done} done"
        )
      when :cancelled
        raise "Startup sequence '#{sequencer.sequence}' not followed: #{collector.error}"
      end
    end

    private :handle_startup_sequence_item, :handle_startup_sequence_result

    def switch_normal_control
      set_functional_position 'NormalControl'
      wait_normal_control
    end

    def switch_fixed_time(status)
      apply_fixed_time status
      wait_for_status(
        "fixed time to be #{status}",
        [{ 'sCI' => 'S0009', 'n' => 'status', 's' => /^#{status}(,#{status})*$/ }]
      )
    end

    def switch_input(indx)
      set_input 'True', indx.to_s

      # Index is 1-based, convert to 0-based for regex
      wait_for_status(
        "input #{indx} to be True",
        [
          { 'sCI' => 'S0003', 'n' => 'inputstatus', 's' => /^.{#{indx - 1}}1/ }
        ]
      )

      set_input 'False', indx.to_s
      wait_for_status(
        "input #{indx} to be False",
        [{ 'sCI' => 'S0003', 'n' => 'inputstatus', 's' => /^.{#{indx - 1}}0/ }]
      )
    end

    def suspend_alarm(site, task, c_id:, a_c_id:, collect:)
      suspend = RSMP::AlarmSuspend.new(
        'mId' => RSMP::Message.make_m_id, # generate a message id, that can be used to listen for responses
        'cId' => c_id,
        'aCId' => a_c_id
      )
      if collect
        collect_task = task.async do
          RSMP::AlarmCollector.new(site,
                                   m_id: suspend.m_id,
                                   num: 1,
                                   matcher: {
                                     'cId' => c_id,
                                     'aCI' => a_c_id,
                                     'aSp' => 'Suspend',
                                     'sS' => /^Suspended/i
                                   },
                                   timeout: Validator.config['timeouts']['alarm']).collect!
        end
        site.send_message suspend
        [suspend, collect_task.wait.first]
      else
        site.send_message suspend
        suspend
      end
    end

    def resume_alarm(site, task, c_id:, a_c_id:, collect:)
      resume = RSMP::AlarmResume.new(
        'mId' => RSMP::Message.make_m_id, # generate a message id, that can be used to listen for responses
        'cId' => c_id,
        'aCId' => a_c_id
      )
      if collect
        collect_task = task.async do
          RSMP::AlarmCollector.new(site,
                                   m_id: resume.m_id,
                                   num: 1,
                                   matcher: {
                                     'cId' => c_id,
                                     'aCI' => a_c_id,
                                     'aSp' => 'Suspend',
                                     'sS' => /^notSuspended/i
                                   },
                                   timeout: Validator.config['timeouts']['alarm']).collect!
        end
        site.send_message resume
        [resume, collect_task.wait.first]
      else
        site.send_message resume
        resume
      end
    end

    def prepare(task, site)
      @task = task
      @site = site
    end
  end
end
