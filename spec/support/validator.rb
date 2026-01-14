# frozen_string_literal: true

require 'rsmp'
require 'colorize'
require 'rspec/expectations'

# Main module for RSMP Validator functionality
# Handles configuration, logging, and coordination between RSpec and the RSMP gem
module Validator
  include RSpec::Matchers

  class << self
    include RSMP::Logging

    attr_accessor :config, :mode, :logger, :reporter, :auto_node_config, :auto_node
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
    settings = settings.deep_merge(config['log']) if config['log']
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
    reporter.publish :step, message: str
  end

  # log to the rspec formatter
  def self.warning(str, _options = {})
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

  # get the path of our config file, which depend on whether we're testing a site or supervisor
  # First check SITE_CONFIG or SUPERVISOR_CONFIG
  # Then look for the key 'site' or 'supervisor' in config/validator.yaml
  def self.get_config_path(local: false)
    mode = self.mode.to_s
    config_path = get_config_path_from_env(mode) || get_config_path_from_validator_yaml(mode)
    abort_with_error "#{mode.capitalize} config path not set" unless config_path && config_path != ''

    config_path = File.expand_path(config_path) if local
    config_path
  end

  def self.get_config_path_from_env(mode)
    key = "#{mode.upcase}_CONFIG"
    ENV.fetch(key, nil)
  end

  def self.get_config_path_from_validator_yaml(mode)
    ref_path = 'config/validator.yaml'
    return nil unless File.exist? ref_path

    config_ref = YAML.load_file ref_path
    config_ref[mode].to_s.strip
  end

  # load config from a YAML file
  def self.load_tester_config
    config_path = get_config_path

    self.config = load_yaml_config!(
      config_path,
      using_message: "Using #{mode} config: #{config_path}",
      missing_message: "#{mode.capitalize} config file #{config_path} is missing"
    )

    validate_mode_config!(config_path)
    validate_components_config!
    validate_timeouts_config!
    normalize_core_version!
    load_secrets config_path
  end

  def self.load_yaml_config!(path, using_message:, missing_message:)
    abort_with_error missing_message unless File.exist?(path)

    puts using_message
    YAML.load_file path
  end

  def self.validate_mode_config!(config_path)
    case mode
    when :supervisor
      return unless config['port']

      abort_with_error <<~HEREDOC
        Error:
        The config file at #{config_path} has a 'port' element, which is not expected when testing a supervisor.
        For supervisor testing, the config should describe the local site used during testing.
        Check that you're using the right config file, or fix the config.
      HEREDOC
    when :site
      return unless config['supervisors']

      abort_with_error <<~HEREDOC
        Error:
        The config file at #{config_path} has a 'supervisors' element, which is not expected when testing a site.
        For site testing, the config should describe the local supervisor used during testing.
        Check that you're using the right config file, or fix the config.
      HEREDOC
    end
  end

  def self.validate_components_config!
    abort_with_error "Error: config 'components' settings is missing or empty" if config['components'] == {}

    main_component = config.dig('components', 'main')&.keys&.first
    abort_with_error "Error: config 'main' component settings is missing or empty" unless main_component

    config['main_component'] = main_component
  end

  def self.validate_timeouts_config!
    timeouts = config['timeouts']
    abort_with_error "Error: config 'timeouts' settings is missing or empty" if timeouts.nil? || timeouts == {}
  end

  def self.normalize_core_version!
    core_version = ENV['CORE_VERSION'] || config['core_version'] || RSMP::Schema.latest_core_version
    core_version = RSMP::Schema.latest_core_version if core_version == 'latest'

    known_versions = RSMP::Schema.core_versions
    normalized_core_version = normalized_core_version(core_version, known_versions)
    return config['core_version'] = normalized_core_version.to_s if normalized_core_version

    abort_with_error "Unknown core version #{core_version}, must be one of [#{known_versions.join(', ')}]."
  end

  def self.normalized_core_version(core_version, known_versions)
    # 3.2 will match 3.2.0
    known_versions.map { |v| Gem::Version.new(v) }.sort.reverse.detect do |v|
      Gem::Requirement.new(core_version).satisfied_by?(v)
    end
  end

  # load auto node config from a YAML file
  # this is the config for the local site/supervisor that will be started for testing
  def self.load_auto_node_config
    path = auto_node_config_path
    return unless path

    # load auto config
    if File.exist? path
      puts "Will run auto #{mode} with config: #{path}"
      self.auto_node_config = YAML.load_file path
    else
      abort_with_error "Auto #{mode} config file #{path} is missing"
    end
  end

  # get the path of the auto config file
  # First check AUTO_SITE_CONFIG or AUTO_SUPERVISOR_CONFIG environment variables
  # Then look for 'auto_site' or 'auto_supervisor' keys in config/validator.yaml
  def self.auto_node_config_path
    # Check environment variable first
    env_key = mode == :site ? 'AUTO_SITE_CONFIG' : 'AUTO_SUPERVISOR_CONFIG'
    env_path = ENV.fetch(env_key, nil)
    return env_path if env_path && !env_path.empty?

    # Fall back to validator.yaml
    ref_path = 'config/validator.yaml'
    return nil unless File.exist? ref_path

    config_ref = YAML.load_file ref_path
    key = mode == :site ? 'auto_site' : 'auto_supervisor'
    path = config_ref[key].to_s.strip
    path.empty? ? nil : path
  end

  # load secrets
  # secrets can be added directly to the config file in which
  # case no file needs to be loaded.
  # otherwise  look for a path relative to config_path, e.g.
  # if config_path is 'gem_site.yaml', look for 'gem_site_secrets.yaml'
  # if not found, try the the generic path 'secrets.yaml'
  def self.load_secrets(config_path)
    load_secrets_file(config_path) unless config['secrets']
    warn_missing_security_codes
  end

  def self.load_secrets_file(config_path)
    basename = File.basename(config_path, '.yaml')
    folder = File.dirname(config_path)
    secrets_path = File.join(folder, "#{basename}_secrets.yaml")
    return unless File.exist?(secrets_path)

    config['secrets'] = YAML.load_file(secrets_path)
  end

  def self.warn_missing_security_codes
    return warn_no_security_code unless config.dig('secrets', 'security_codes')

    warn_security_code_not_configured(1) unless config.dig('secrets', 'security_codes', 1)
    warn_security_code_not_configured(2) unless config.dig('secrets', 'security_codes', 2)
  end

  def self.warn_no_security_code
    log 'Warning: No security code configured'.colorize(:yellow)
  end

  def self.warn_security_code_not_configured(index)
    log "Warning: Security code #{index} is not configured".colorize(:yellow)
  end

  private_class_method :load_secrets_file, :warn_missing_security_codes, :warn_no_security_code,
                       :warn_security_code_not_configured

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

  def self.get_config(*path, **options)
    value = Validator.config.dig(*path)
    if value
      value
    else
      path_name = path.inspect

      default = options[:default]
      assume = options[:assume]
      if default
        warning "Config #{path_name} not found, using default: #{default}"
        default
      elsif assume
        assume
      else
        raise "Config #{path_name} is missing"
      end
    end
  end
end
