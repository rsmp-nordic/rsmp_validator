# Base class for automatically starting a local RSMP node (site or supervisor)
# to be tested. The node runs inside the same Async reactor context as the tester.
#
# When auto_config is provided in the validator config, this allows programmatic
# testing of the RSMP gem or test suite itself, without requiring an external
# site or supervisor.

require 'rsmp'

class Validator::AutoNode
  attr_reader :node, :task

  def initialize
    @node = nil
    @task = nil
  end

  # Start the auto node inside the async reactor
  # This method should be called from within the reactor context
  def start
    return if @node

    @node = build_node

    # Run the node in a separate async task within the same reactor
    @task = Async do |task|
      task.annotate "auto_#{node_type}"
      Validator::Log.log_block("Starting auto #{node_type}") do
        @node.start # This will keep running until stopped
      end
    end
  end

  # Stop the auto node
  def stop
    if @node
      Validator::Log.log "Stopping auto #{node_type}", level: :info
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

  # Get the configuration for this auto node
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
    # start with validator's logger settings as base
    logger_settings = Validator.logger.settings.dup

    # if auto node config has log settings, merge them
    logger_settings.merge!(config['log']) if config['log']

    # If path is explicitly set, remove stream to allow file output
    # Otherwise, keep the validator's stream for consistent formatting
    logger_settings.delete('stream') if config['log']['path']

    RSMP::Logger.new(logger_settings)
  end
end
