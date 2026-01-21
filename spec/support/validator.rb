require 'rsmp'
require 'colorize'
require 'rspec/expectations'
require_relative 'options/site_test_options'
require_relative 'options/supervisor_test_options'
require_relative 'config_normalizer'
require_relative 'validator/configuration'

# Main module for RSMP Validator functionality
# Handles configuration, logging, and coordination between RSpec and the RSMP gem
module Validator
  include RSpec::Matchers
  extend Configuration

  class << self
    include RSMP::Logging

    attr_accessor :config, :config_log_settings, :mode, :logger, :reporter, :auto_node_config,
                  :auto_node_log_settings, :auto_node
  end

  # Get the global Async reactor used for RSMP communication
  def self.reactor
    @reactor
  end

  # Initialize the validator system at RSpec startup
  def self.setup(rspec_config)
    determine_mode rspec_config.files_to_run
    load_tester_config
    load_auto_node_config
    setup_logging rspec_config
    build_auto_node
    build_tester
    setup_filters rspec_config
  end

  # Set up logging system with custom settings and colors
  def self.setup_logging(rspec_config)
    settings = {
      'stream' => ReportStream.new(rspec_config.reporter),
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
    self.reporter = rspec_config.reporter
  end

  # Called by RSpec at startup - initializes the Async reactor and checks connectivity
  def self.before_suite(_examle)
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
    reactor.run do |task|
      auto_node&.start
      Validator.check_connection
    rescue StandardError => e
      error = e
      task.stop
    ensure
      reactor.interrupt
    end
    error
  end

  def self.abort_startup(exception, message)
    warn "Aborting: #{message}".colorize(:red)
    raise exception
  end

  private_class_method :setup_reactor, :run_startup_checks, :abort_startup

  # Called by RSpec when each test is being run
  # Manages the Async reactor and fiber-local data for RSpec compatibility
  def self.around_each(example)
    thread_local_data = RSpec::Support.thread_local_data
    reactor.run do |task|
      # rspec depends on thread-local data (which is actually fiber-local),
      # but the async task runs in a different fiber. as a work-around,
      # we copy the data into the current fiber-local storage
      thread_local_data.each_pair { |key, value| RSpec::Support.thread_local_data[key] = value }
      task.annotate 'rspec'
      example.run
    ensure
      reactor.interrupt
    end
  end

  # Initial connectivity check to verify we can connect to the site/supervisor being tested
  def self.check_connection
    Validator::Log.log "Initial #{mode} connection check"
    if mode == :site
      Validator::SiteTester.instance.connected { nil }
    elsif mode == :supervisor
      Validator::SupervisorTester.instance.connected { nil }
    end
    log ''
  end

  # log to the rspec formatter
  def self.log(str, _options = {})
    return puts(str) unless reporter

    reporter.publish :step, message: str
  end

  # log to the rspec formatter
  def self.warning(str, _options = {})
    return warn(str) unless reporter

    reporter.publish :warning, message: str
  end

  # print and error to STDERR and exit with an error
  def self.abort_with_error(error)
    warn "Error: #{error}".colorize(:red)
    exit 1
  end

  # set whether we are testing a site or a supervisor
  def self.select_mode(mode)
    if self.mode
      abort_with_error 'Cannot test run specs in both spec/site/ and spec/supervisor/' if self.mode != mode
      return
    end

    case mode
    when :site, :supervisor
      self.mode = mode
    else
      abort_with_error "Unknown test mode: #{mode}"
    end
  end

  # find out whether we're testing a site or a supervisor,
  # based on the path to the specs we're going to run
  def self.determine_mode(files_to_run)
    site_folder = './spec/site'
    supervisor_folder = './spec/supervisor'
    site_folder_full_path = File.expand_path(site_folder)
    supervisor_folder_full_path = File.expand_path(supervisor_folder)

    files_to_run.each do |path_str|
      path = Pathname.new(path_str)
      if path.fnmatch?(File.join(site_folder_full_path, '**'))
        select_mode :site
      elsif path.fnmatch?(File.join(supervisor_folder_full_path, '**'))
        select_mode :supervisor
      else
        abort_with_error "Spec #{path_str} is neither a site nor supervisor test"
      end
    end
  end

  # build the tester, which can be a Validator::SiteTester or a Validator::SupervisorTester,
  # depending on what we're going to test
  def self.build_tester
    if mode == :site
      Validator::SiteTester.instance = Validator::SiteTester.new
    elsif mode == :supervisor
      Validator::SupervisorTester.instance = Validator::SupervisorTester.new
    else
      abort_with_error "Unknown test mode: #{mode}"
    end
  end

  # build the auto node (local site or supervisor to be tested)
  # this is only done if auto_node_config is loaded
  def self.build_auto_node
    return unless auto_node_config

    if mode == :site
      self.auto_node = Validator::AutoSite.new
    elsif mode == :supervisor
      self.auto_node = Validator::AutoSupervisor.new
    else
      abort_with_error "Unknown test mode: #{mode}"
    end
  end

  # setup rspec filters to support filtering by RSMP core and SXL version tags
  def self.setup_filters(rspec_config)
    setup_version_filter(rspec_config, tag: :core, config_key: 'core_version')
    setup_version_filter(rspec_config, tag: :sxl, config_key: 'sxl_version')
  end

  def self.setup_version_filter(rspec_config, tag:, config_key:)
    version_str = Validator.config[config_key]
    return unless version_str

    version = Gem::Version.new(version_str)
    filter = ->(v) { !Gem::Requirement.new(v).satisfied_by?(version) }
    filter.define_singleton_method(:inspect) do
      "[unless relevant for #{Validator.config[config_key]}]"
    end
    rspec_config.filter_run_excluding(tag => filter)
  end

  private_class_method :setup_version_filter
end
