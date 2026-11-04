module RSMP
  module Validator
    module Helpers
      # Helper methods for testing RSMP signal plan functionality.
      module SignalPlans
        # Keep assertions and their return guards together in the setup flow.
        # rubocop:disable-next Metrics/AbcSize
        def with_cycle_time_extended(site_proxy, extension = 5, &block)
          timeout = RSMP::Validator.get_config('timeouts', 'command_response')
          plan = site_proxy.tlc.read_current_plan!
          time = site_proxy.tlc.read_cycle_times![plan]
          expect(time).not.to be_nil
          return if time.nil?

          time_extended = time + extension
          need_to_reset = true
          site_proxy.tlc.set_cycle_time!(plan: plan, cycle_time: time_extended, within: timeout)
          actual = site_proxy.tlc.read_cycle_times![plan]
          expect(actual).to be == time_extended
          return unless actual == time_extended

          block.yield
        ensure
          if need_to_reset
            log 'Reset cycle time'
            site_proxy.tlc.set_cycle_time!(plan: plan, cycle_time: time, within: timeout)
          end
        end
      end
    end
  end
end
