require 'rsmp'
require 'colorize'
require_relative 'validator/version'
require_relative 'validator/log'
require_relative 'validator/options/site_test_options'
require_relative 'validator/options/supervisor_test_options'
require_relative 'validator/config_check'
require_relative 'validator/config_normalizer'
require_relative 'validator/configuration'
require_relative 'validator/version_filter'
require_relative 'validator/lifecycle'
require_relative 'validator/mode_detection'
require_relative 'validator/tester'
require_relative 'validator/site_tester'
require_relative 'validator/supervisor_tester'
require_relative 'validator/auto_node'
require_relative 'validator/auto_site'
require_relative 'validator/auto_supervisor'
require_relative 'validator/async_context'
require_relative 'validator/helpers/connection'
require_relative 'validator/helpers/status'
require_relative 'validator/helpers/input'
require_relative 'validator/helpers/clock'
require_relative 'validator/helpers/security'
require_relative 'validator/helpers/signal_plans'
require_relative 'validator/helpers/alarms'
require_relative 'validator/helpers/startup'
require_relative 'validator/helpers/handshake'
require_relative 'validator/helpers/signal_priority'

module RSMP
  # Main module for RSMP Validator functionality.
  # Handles configuration, logging, and coordination between sus and the RSMP gem.
  module Validator
    extend Configuration
    extend Lifecycle
    extend ModeDetection

    class << self
      include RSMP::Logging

      attr_accessor :config, :config_log_settings, :mode, :logger, :auto_node_config,
                    :auto_node_log_settings, :auto_node, :node_log_settings,
                    :core_version_override, :sxls_override, :site_config_path,
                    :supervisor_config_path, :auto_site_config_path,
                    :auto_supervisor_config_path, :config_path
    end

    # Get the global Async reactor used for RSMP communication
    def self.reactor
      @reactor
    end
  end
end
