require 'rsmp'
require 'colorize'
require_relative 'validator/version'
require_relative 'validator/log'
require_relative 'validator/options/site_test_options'
require_relative 'validator/options/supervisor_test_options'
require_relative 'validator/config_normalizer'
require_relative 'validator/configuration'
require_relative 'validator/version_filter'
require_relative 'validator/tester'
require_relative 'validator/site_tester'
require_relative 'validator/supervisor_tester'
require_relative 'validator/auto_node'
require_relative 'validator/auto_site'
require_relative 'validator/auto_supervisor'
require_relative 'validator/async_context'
require_relative 'validator/helpers/status'
require_relative 'validator/helpers/commands'
require_relative 'validator/helpers/input'
require_relative 'validator/helpers/clock'
require_relative 'validator/helpers/security'
require_relative 'validator/helpers/signal_plans'
require_relative 'validator/helpers/alarms'
require_relative 'validator/helpers/startup'
require_relative 'validator/helpers/handshake'
require_relative 'validator/helpers/signal_priority'

# Main module for RSMP Validator functionality.
# Handles configuration, logging, and coordination between sus and the RSMP gem.
module Validator
  extend Configuration

  class << self
    include RSMP::Logging

    attr_accessor :config, :config_log_settings, :mode, :logger, :auto_node_config,
                  :auto_node_log_settings, :auto_node
  end

  # Get the global Async reactor used for RSMP communication
  def self.reactor
    @reactor
  end

  # Initialize the validator system at sus startup
  def self.setup(sus_config)
    determine_mode sus_config
    initialize_logging log_settings: {} # minimal init so log() works during config loading
    load_tester_config
    load_auto_node_config
    setup_logging # reinitialize with config-specific settings
    build_auto_node
    build_tester
  end

  # Set up logging system
  def self.setup_logging
    settings = {
      'stream' => $stdout,
      'color' => {
        'info' => 'light_black',
        'log' => 'white',
        'test' => 'white',
        'debug' => 'light_black'
      },
      'port' => true,
      'json' => true,
      'acknowledgements' => true,
      'watchdogs' => true,
      'test' => true,
      'debug' => true
    }
    settings = settings.deep_merge(config_log_settings) if config_log_settings
    settings = settings.deep_merge(config['log']) if config.is_a?(Hash) && config['log']
    initialize_logging log_settings: settings
  end

  # Called at sus startup - initializes the Async reactor and checks connectivity
  def self.before_suite
    setup_reactor
    error = run_startup_checks
    raise error if error
  rescue RSMP::ConnectionError => e
    abort_startup(e, e.message)
  rescue StandardError => e
    abort_startup(e, e.inspect)
  end

  def self.setup_reactor
    @reactor = Async::Reactor.new
    reactor.annotate 'reactor'
  end

  def self.run_startup_checks
    error = nil
    reactor.run do |_task|
      auto_node&.start
      check_connection
    rescue StandardError => e
      error = e
    ensure
      reactor.interrupt
    end
    error
  end

  def self.abort_startup(exception, message)
    warn "Aborting: #{message}".colorize(:red)
    raise exception
  end

  # Called at sus shutdown
  def self.after_suite
    reactor.run do |_task|
      auto_node&.stop
    ensure
      reactor.interrupt
    end
  rescue StandardError
    nil
  end

  # Initial connectivity check to verify we can connect to the site/supervisor being tested
  def self.check_connection
    Log.log "Initial #{mode} connection check"
    if mode == :site
      SiteTester.instance.connected { nil }
    elsif mode == :supervisor
      SupervisorTester.instance.connected { nil }
    end
  end

  def self.abort_with_error(error)
    warn "Error: #{error}".colorize(:red)
    exit 1
  end

  # Set whether we are testing a site or a supervisor
  def self.select_mode(mode)
    if self.mode
      abort_with_error 'Cannot run tests in both test/site/ and test/supervisor/' if self.mode != mode
      return
    end

    case mode
    when :site, :supervisor
      self.mode = mode
    else
      abort_with_error "Unknown test mode: #{mode}"
    end
  end

  # Determine mode from test file paths
  def self.determine_mode(sus_config)
    paths = sus_config.paths.any? ? sus_config.paths : sus_config.test_paths
    site_dir = File.expand_path('test/site', sus_config.root)
    supervisor_dir = File.expand_path('test/supervisor', sus_config.root)

    paths.each do |path_str|
      expanded = File.expand_path(path_str, sus_config.root)
      inferred = infer_mode_from_path(expanded, site_dir, supervisor_dir)
      select_mode inferred if inferred
    end

    abort_with_error 'Could not determine test mode (site or supervisor) from test paths' unless mode
  end

  # Determine the test mode from a single expanded path
  def self.infer_mode_from_path(path, site_dir, supervisor_dir)
    return :site if path == site_dir || path.start_with?("#{site_dir}/")
    return :supervisor if path == supervisor_dir || path.start_with?("#{supervisor_dir}/")

    nil
  end

  # Build the tester instance
  def self.build_tester
    if mode == :site
      SiteTester.instance = SiteTester.new
    elsif mode == :supervisor
      SupervisorTester.instance = SupervisorTester.new
    else
      abort_with_error "Unknown test mode: #{mode}"
    end
  end

  # Build the auto node (local site or supervisor to be tested)
  def self.build_auto_node
    return unless auto_node_config

    if mode == :site
      self.auto_node = AutoSite.new
    elsif mode == :supervisor
      self.auto_node = AutoSupervisor.new
    else
      abort_with_error "Unknown test mode: #{mode}"
    end
  end

  private_class_method :run_startup_checks, :abort_startup
end
