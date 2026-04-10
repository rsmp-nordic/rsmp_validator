module Validator
  module Helpers
    # Helper methods for testing RSMP clock functionality.
    module Clock
      def with_clock_set(site_proxy, clock)
        site_proxy.set_clock(clock, options: { collect!: { timeout: Validator.get_config('timeouts', 'command_response') } })
        site_proxy.clear_alarm_timestamps
        yield
      ensure
        site_proxy.set_clock(Time.now.utc)
      end
    end
  end
end
