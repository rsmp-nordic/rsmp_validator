require 'rsmp'

module Validator
  # Base class for automatically starting a local RSMP node (site or supervisor)
  # when testing the validator or RSMP gem itself.
  class AutoNode
    attr_reader :node, :task

    def initialize
      @node = nil
      @task = nil
    end

    # Start the auto node inside the async reactor
    def start
      return if @node

      @node = build_node

      @task = Async do |task|
        task.annotate "auto_#{node_type}"
        Log.log_block("Starting auto #{node_type}") do
          @node.start
        end
      end
    end

    # Stop the auto node
    def stop
      if @node
        Log.log "Stopping auto #{node_type}", level: :info
        @node.ignore_errors RSMP::DisconnectError do
          @node.stop
        end
      end
      @task&.stop
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
      Validator.auto_node_config
    end

    def node_type
      raise NotImplementedError, 'Subclasses must implement node_type'
    end

    def build_node
      raise NotImplementedError, 'Subclasses must implement build_node'
    end

    def create_logger
      logger_settings = Validator.logger.settings.dup
      auto_log_settings = Validator.auto_node_log_settings
      logger_settings.merge!(auto_log_settings) if auto_log_settings && !auto_log_settings.empty?
      logger_settings.delete('stream') if auto_log_settings && auto_log_settings['path']
      RSMP::Logger.new(logger_settings)
    end
  end
end
