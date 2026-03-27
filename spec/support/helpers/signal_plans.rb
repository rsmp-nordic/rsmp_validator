module Validator
  module Helpers
    module SignalPlans
      def with_cycle_time_extended(site, extension = 5, &block)
        plan = site.read_current_plan
        time = read_plan_cycle_time(site, plan)
        need_to_reset = true
        time_extended = time + extension
        site.set_cycle_time(plan: plan, cycle_time: time_extended)
        verify_cycle_time(site, plan, time_extended)
        block.yield
      ensure
        if need_to_reset
          log 'Reset cycle time'
          site.set_cycle_time(plan: plan, cycle_time: time)
        end
      end

      private

      def read_plan_cycle_time(site, plan)
        time = site.read_cycle_times[plan]
        expect(time).not_to be_nil, 'Site returned empty cycle times list'
        time
      end

      def verify_cycle_time(site, plan, expected)
        actual = site.read_cycle_times[plan]
        expect(actual).to eq(expected)
      end
    end
  end
end
