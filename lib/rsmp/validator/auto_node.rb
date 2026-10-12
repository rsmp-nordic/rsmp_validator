require 'rsmp'

module RSMP
  module Validator
    # Base class for automatically starting a local RSMP node (site or supervisor)
    # when testing the validator or RSMP gem itself.
    class AutoNode
      include RSMP::Validator::Log

      attr_reader :node, :task

      def initialize
        @node = nil
        @task = nil
      end

      # Start the auto node inside the async reactor
      def start
        return if @node

        @node = build_node
        log("Starting auto #{node_type}")
        @task = @node.start(parent: Async::Task.current)
      end

      # Stop the auto node
      def stop
        log("Stopping auto #{node_type}") if @node
        @node&.stop
        @task&.wait
      ensure
        @task = nil
        @node = nil
      end

      # Check if the auto node is running
      def running?
        @node && @task
      end

      protected

      def config
        RSMP::Validator.auto_node_config
      end

      def node_type
        raise NotImplementedError, 'Subclasses must implement node_type'
      end

      def build_node
        raise NotImplementedError, 'Subclasses must implement build_node'
      end

      def create_logger
        logger_settings = RSMP::Validator.node_log_settings.dup
        logger_settings['prefix'] = default_log_prefix
        auto_log_settings = RSMP::Validator.auto_node_log_settings
        logger_settings.merge!(auto_log_settings) if auto_log_settings && !auto_log_settings.empty?
        logger_settings.delete('stream') if auto_log_settings && auto_log_settings['path']
        RSMP::Logger.new(logger_settings)
      end

      def default_log_prefix
        case node_type
        when 'supervisor' then '[SUPERVISOR]'
        when 'site'       then '[TLC]       '
        end
      end
    end
  end
end
