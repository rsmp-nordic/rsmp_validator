# Automatically starts a local RSMP supervisor to be tested
# This is used when testing the validator or RSMP gem itself
# The supervisor runs inside the same Async reactor context as the tester

require_relative 'auto_node'

module Validator
  class AutoSupervisor < Validator::AutoNode
    protected

    def node_type
      'supervisor'
    end

    # Build a local RSMP supervisor that will be tested
    # The supervisor configuration comes from the auto_config loaded from validator.yaml
    def build_node
      # Create the supervisor with the auto_config settings
      RSMP::Supervisor.new(
        supervisor_settings: config,
        logger: create_logger
      )
    end
  end
end
