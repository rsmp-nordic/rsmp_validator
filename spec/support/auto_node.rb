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

    Validator.log "Starting auto #{node_type}", level: :info
    
    @node = build_node
    
    # Run the node in a separate async task within the same reactor
    @task = Async do |task|
      task.annotate "auto_#{node_type}"
      begin
        @node.start  # This will keep running until stopped
      rescue StandardError => e
        Validator.log "Auto #{node_type} error: #{e.class}: #{e.message}", level: :error
        raise
      end
    end
  end

  # Stop the auto node
  def stop
    if @node
      Validator.log "Stopping auto #{node_type}", level: :info
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
    raise NotImplementedError, "Subclasses must implement node_type"
  end

  def build_node
    raise NotImplementedError, "Subclasses must implement build_node"
  end
end
