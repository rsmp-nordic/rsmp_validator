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

    def with_cycle_time_extended(site, extension = 5, &block)
      # read current plan
      plan = read_current_plan(site)

      # read initial cycle times
      times = read_cycle_times(site)
      time = times[plan]

      expect(time).not_to be_nil, 'Site returned empty cycle times list'

      # change cycle time
      time_extended = time + extension
      need_to_reset = true
      @site.set_cycle_time(plan: plan, cycle_time: time_extended)

      # read updated cycle times
      times = read_cycle_times(site, 'updated cycle times')
      time_extended_actual = times[plan]
      expect(time_extended_actual).to eq(time_extended)

      block.yield
    ensure
      if need_to_reset
        log 'Reset cycle time'
        @site.set_cycle_time(plan: plan, cycle_time: time)
      end
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
      @site.force_input(input: input, status: 'True', value: value)
      digit = (value == 'True' ? '1' : '0')

      # Index is 1-based, convert to 0-based for regex
      wait_for_status(
        "input #{input} to be #{value}",
        [
          { 'sCI' => 'S0003', 'n' => 'inputstatus', 's' => /^.{#{input - 1}}#{digit}/ }
        ]
      )
    end

    def stop_sending_watchdogs(site)
      # monkey-patch the site object by redefining
      # the send_watchdog method to do nothing
      def site.send_watchdog(now = nil); end
    end

    def with_clock_set(site, clock)
      @site.set_clock(clock, options: { collect!: { timeout: Validator.get_config('timeouts', 'command_response') } })
      site.clear_alarm_timestamps
      yield
    ensure
      @site.set_clock(Time.now.utc)
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

    def switch_input(indx)
      @site.set_input(input: indx.to_s, status: 'True')

      # Index is 1-based, convert to 0-based for regex
      wait_for_status(
        "input #{indx} to be True",
        [
          { 'sCI' => 'S0003', 'n' => 'inputstatus', 's' => /^.{#{indx - 1}}1/ }
        ]
      )

      @site.set_input(input: indx.to_s, status: 'False')
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
