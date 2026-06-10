module Validator
  module Helpers
    # Helper methods for testing RSMP clock functionality.
    module Clock
      def with_clock_set(site_proxy, clock, within:)
        site_proxy.tlc.set_clock(clock, within:)
        site_proxy.clear_alarm_timestamps
        yield
      ensure
        site_proxy.tlc.set_clock(Time.now.utc, within:)
      end
    end
  end
end
