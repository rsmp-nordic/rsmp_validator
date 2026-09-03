require 'rsmp'
require 'colorize'

module RSMP
  module Validator
    # Base class for testing either a site or a supervisor.
    # Handles running the corresponding local site/supervisor inside an Async reactor.
    class Tester
      include RSMP::Validator::Log

      def config
        RSMP::Validator.config
      end

      # Ensures that the site is connected.
      # If the site is already connected, the block will be called immediately.
      # Otherwise waits until the site is connected before calling the block.
      def connected(options = {})
        start options, 'Connecting'
        wait_for_proxy
        result = yield Async::Task.current, @node, @proxy
        check_health
        result
      end

      # Disconnects the site if connected, then waits until the site is connected
      # before calling the block.
      def reconnected(options = {})
        stop 'Reconnecting'
        start options
        wait_for_proxy
        result = yield Async::Task.current, @node, @proxy
        check_health
        result
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

      # Stop the rsmp supervisor
      def stop(why = nil)
        log why if why && @node
        @node&.stop
        @node_task&.wait
        @node_task = nil
        @node = nil
        @proxy = nil
      end

      def receive_event(event)
        failure = event.failure
        detail = failure ? "#{failure.code}: #{failure.message}" : event.type
        log "Node event: #{detail}", level: :debug
      end

      private

      def check_health
        @node_task.wait if @node_task&.failed?
      end

      def initialize
        parse_config
      end

      # Start the tester node under the shared reactor's current task.
      def start(options = {}, _why = nil)
        return if @node

        @node = build_node options
        @node.add_event_receiver(self)
        @node_task = @node.start(parent: Async::Task.current)
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
