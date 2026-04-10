module Validator
  module Helpers
    # Helper methods for testing RSMP signal plan functionality.
    module SignalPlans
      def with_cycle_time_extended(site_proxy, extension = 5, &block)
        plan = site_proxy.read_current_plan
        time = read_plan_cycle_time(site_proxy, plan)
        need_to_reset = true
        time_extended = time + extension
        site_proxy.set_cycle_time(plan: plan, cycle_time: time_extended)
        verify_cycle_time(site_proxy, plan, time_extended)
        block.yield
      ensure
        if need_to_reset
          log 'Reset cycle time'
          site_proxy.set_cycle_time(plan: plan, cycle_time: time)
        end
      end

      private

      def read_plan_cycle_time(site_proxy, plan)
        time = site_proxy.read_cycle_times[plan]
        assert(!time.nil?, 'Site returned empty cycle times list')
        time
      end

      def verify_cycle_time(site_proxy, plan, expected)
        actual = site_proxy.read_cycle_times[plan]
        assert(actual == expected, "Expected cycle time #{expected}, got #{actual}")
      end
    end
  end
end
