require_relative 'auto_node'

module Validator
  # Automatically starts a local RSMP supervisor for testing.
  class AutoSupervisor < Validator::AutoNode
    protected

    def node_type
      'supervisor'
    end

    def build_node
      RSMP::Supervisor.new(
        supervisor_settings: config,
        logger: create_logger
      )
    end
  end
end
