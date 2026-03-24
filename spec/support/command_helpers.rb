module Validator
  module CommandHelpers
    # Send an RSMP command and wait for confirmation response
    def send_command_and_confirm(command_list, message,
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

    def with_cycle_time_extended(site, extension = 5, &block)
      # read current plan
      plan = site.read_current_plan

      # read initial cycle times
      times = site.read_cycle_times
      time = times[plan]

      expect(time).not_to be_nil, 'Site returned empty cycle times list'

      # change cycle time
      time_extended = time + extension
      need_to_reset = true
      site.set_cycle_time(plan: plan, cycle_time: time_extended)

      # read updated cycle times
      times = site.read_cycle_times
      time_extended_actual = times[plan]
      expect(time_extended_actual).to eq(time_extended)

      block.yield
    ensure
      if need_to_reset
        log 'Reset cycle time'
        site.set_cycle_time(plan: plan, cycle_time: time)
      end
    end

    # Check if security codes are configured, skip test if not available
    def require_security_codes
      return if Validator.config.dig 'secrets', 'security_codes'

      skip 'Security codes are not configured'
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
      @site.wait_for_normal_control(timeout: timeout)
    end

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

    def prepare(task, site)
      @task = task
      @site = site
    end
  end
end
