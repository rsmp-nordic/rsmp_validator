module RSMP
  module Validator
    module Helpers
      # Helper methods for testing RSMP signal plan functionality.
      module SignalPlans
        def with_cycle_time_extended(site_proxy, extension = 5, &block)
          timeout = RSMP::Validator.get_config('timeouts', 'command_response')
          plan = site_proxy.tlc.read_current_plan!
          time = read_plan_cycle_time(site_proxy, plan)
          time_extended = time + extension
          need_to_reset = true
          site_proxy.tlc.set_cycle_time!(plan: plan, cycle_time: time_extended, within: timeout)
          verify_cycle_time(site_proxy, plan, time_extended)
          block.yield
        ensure
          if need_to_reset
            log 'Reset cycle time'
            site_proxy.tlc.set_cycle_time!(plan: plan, cycle_time: time, within: timeout)
          end
        end

        private

        def read_plan_cycle_time(site_proxy, plan)
          time = site_proxy.tlc.read_cycle_times![plan]
          fail_test('Site returned empty cycle times list') if time.nil?
          time
        end

        def verify_cycle_time(site_proxy, plan, expected)
          actual = site_proxy.tlc.read_cycle_times![plan]
          fail_test("Expected cycle time #{expected}, got #{actual}") unless actual == expected
        end
      end
    end
  end
end
