module Validator
  module Helpers
    module Clock
      def with_clock_set(site, clock)
        site.set_clock(clock, options: { collect!: { timeout: Validator.get_config('timeouts', 'command_response') } })
        site.clear_alarm_timestamps
        yield
      ensure
        site.set_clock(Time.now.utc)
      end
    end
  end
end
