require_relative 'auto_node'

module Validator
  # Automatically starts a local RSMP supervisor for testing.
  class AutoSupervisor < Validator::AutoNode
    protected

    def node_type
      'supervisor'
    end

    def build_node
      supervisor_settings = ConfigNormalizer.normalize_supervisor_settings(config)

      RSMP::Supervisor.new(
        supervisor_settings: supervisor_settings,
        logger: create_logger
      )
    end
  end
end
