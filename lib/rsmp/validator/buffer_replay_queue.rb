require 'rsmp'

module RSMP
  module Validator
    # Collect replayed updates and use the reconnect handshake to locate them on the site's clock.
    class BufferReplayQueue < RSMP::Queue
      def initialize(proxy, component:)
        super(proxy, filter: RSMP::Filter.new(type: %w[Watchdog StatusUpdate], outgoing: false, component: component))
        # The proxy installs this queue before sending Version. Receivers see the outbound
        # Version only after the write, which is too late for a guaranteed lower bound.
        @before_version_response = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      def handle_message(message)
        if message.is_a?(RSMP::Watchdog)
          return if @watchdog_received_at

          @watchdog_received_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          @watchdog_site_time = Time.iso8601(message.attribute('wTs'))
        elsif message.is_a?(RSMP::StatusUpdate)
          super
        end
      end

      def site_time_window(offline, margin)
        raise 'Missing site Watchdog from reconnect handshake' unless @watchdog_site_time

        # The site sampled wTs after our Version response and before we received the Watchdog.
        first = @watchdog_site_time - (@before_version_response - offline.begin) + margin
        last = @watchdog_site_time - (@watchdog_received_at - offline.end) - margin
        raise 'Reconnect handshake took too long to establish an offline timestamp window' unless first < last

        first...last
      end
    end
  end
end
