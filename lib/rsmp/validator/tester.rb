require 'rsmp'
require 'colorize'

module RSMP
  module Validator
    # Base class for testing either a site or a supervisor.
    # Handles running the corresponding local site/supervisor inside an Async reactor.
    class Tester
      include RSMP::Validator::Log

      def self.sentinel_errors
        @sentinel_errors ||= []
      end

      def config
        RSMP::Validator.config
      end

      # Ensures that the site is connected.
      # If the site is already connected, the block will be called immediately.
      # Otherwise waits until the site is connected before calling the block.
      def connected(options = {})
        start options, 'Connecting'
        wait_for_proxy
        yield Async::Task.current, @node, @proxy
      end

      # Disconnects the site if connected, then waits until the site is connected
      # before calling the block.
      def reconnected(options = {})
        stop 'Reconnecting'
        start options
        wait_for_proxy
        yield Async::Task.current, @node, @proxy
      end

      # Like connected, except that the connection is closed after the test.
      def isolated(options = {})
        stop 'Isolating'
        start options, 'Connecting'
        wait_for_proxy
        yield Async::Task.current, @node, @proxy
        stop 'Isolating'
      end

      # Disconnects the site if connected before calling the block.
      def disconnected
        stop 'Disconnecting'
        yield Async::Task.current
      end

      # Start the tester node and wait until its listener is ready.
      def start_and_wait_until_ready(options = {})
        return if @node

        @node = build_node options
        ready_waiter = RSMP::Validator.reactor.async { @node.ready_condition.wait }
        start_node_runner
        timeout = config.dig('timeouts', 'connect')
        Async::Task.current.with_timeout(timeout) { ready_waiter.wait }
      rescue Async::TimeoutError
        stop
        raise RSMP::ConnectionError, "Tester node did not become ready within #{timeout}s"
      ensure
        ready_waiter&.stop
      end

      # Stop the rsmp supervisor
      def stop(why = nil)
        if @node
          log why if why
          @node.ignore_errors RSMP::DisconnectError do
            @node.stop
          end
        end
        @node = nil
        @proxy = nil
      end

      private

      def initialize
        parse_config
      end

      # Start the tester node inside an async task that will persist between tests.
      def start(options = {}, _why = nil)
        return if @node

        @node = build_node options
        start_node_runner
      end

      def start_node_runner
        RSMP::Validator.reactor.async do |task|
          task.annotate 'node runner'

          RSMP::Validator.reactor.async do |sentinel|
            sentinel.annotate 'sentinel'
            while @node
              e = @node.error_queue.dequeue
              log "Sentinel warning: #{e.class}: #{e}"
              self.class.sentinel_errors << e
            end
          end

          @node.start
        end
      end

      # Wait until communication has been established, and handshake completed.
      def wait_for_proxy
        wait_for_connection
        wait_for_handshake
      end

      def parse_config; end
    end
  end
end
