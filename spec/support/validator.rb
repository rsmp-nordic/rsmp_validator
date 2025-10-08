require 'rsmp'
require 'colorize'
require 'rspec/expectations'

module Validator
  include RSpec::Matchers

  class << self
    include RSMP::Logging
    attr_accessor :config, :mode, :logger, :reporter, :auto_node_config, :auto_node
  end

  @@reactor = nil

  # get our global reactor
  def self.reactor
    @@reactor
  end

  def self.setup rspec_config
    determine_mode rspec_config.files_to_run
    load_tester_config
    load_auto_node_config
    setup_logging rspec_config
    build_auto_node
    build_tester
    setup_filters rspec_config
  end

  def self.setup_logging rspec_config
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

  # called by rspec at startup
  def self.before_suite examle
    @@reactor = Async::Reactor.new
    reactor.annotate 'reactor'
    error = nil
    reactor.run do |task|
      self.auto_node.start if self.auto_node
      Validator.check_connection
    rescue StandardError => e
      error = e
      task.stop
    ensure
      reactor.interrupt
    end
    raise error if error
  rescue RSMP::ConnectionError => e
    STDERR.puts "Aborting: #{e.message}".colorize(:red)
    raise
  rescue StandardError => e
    STDERR.puts "Aborting: #{e.inspect}".colorize(:red)
    raise
  end

  # called by rspec when each example is being run
  def self.around_each example
    thread_local_data = RSpec::Support.thread_local_data
    reactor.run do |task|
      # rspec depends on thread-local data (which is actually fiber-local),
      # but the async task runs in a different fiber. as a work-around,
      # we copy the data into the current fiber-local storage
      thread_local_data.each_pair { |key,value| RSpec::Support.thread_local_data[key] = value }
      task.annotate 'rspec'
      example.run
    ensure
      reactor.interrupt
    end
  end

  # initial check that we have a connection to the site/supervisor
  def self.check_connection
    Validator::Log.log "Initial #{self.mode} connection check"
    if self.mode == :site
      Validator::SiteTester.instance.connected {}
    elsif self.mode == :supervisor
      Validator::SupervisorTester.instance.connected {}
    end
    self.log ""
  end

  # log to the rspec formatter
  def self.log str, options={}
    self.reporter.publish :step, message: str
  end

  # log to the rspec formatter
  def self.warning str, options={}
    self.reporter.publish :warning, message: str
  end

  private

  # print and error to STDERR and exit with an error
  def self.abort_with_error error
    STDERR.puts "Error: #{error}".colorize(:red)
    exit 1
  end

  # set whether we are testing a site or a supervisor
  def self.set_mode mode
    if self.mode
      if self.mode != mode
        self.abort_with_error "Cannot test run specs in both spec/site/ and spec/supervisor/"
      end
    else
      if mode == :site
        self.mode = mode
      elsif mode == :supervisor
        self.mode = mode
      else
        self.abort_with_error "Unknown test mode: #{mode}"
      end
    end
  end

  # get the path of our config file, which depend on whether we're testing a site or supervisor
  # First check SITE_CONFIG or SUPERVISOR_CONFIG
  # Then look for the key 'site' or 'supervisor' in config/validator.yaml
  def self.get_config_path local: false
    mode = self.mode.to_s
    config_path = get_config_path_from_env(mode) || get_config_path_from_validator_yaml(mode)
    self.abort_with_error "#{mode.capitalize} config path not set" unless config_path && config_path != ''
    config_path
  end

  def self.get_config_path_from_env mode
    key = "#{mode.upcase}_CONFIG"
    ENV[key]
  end
  
  def self.get_config_path_from_validator_yaml mode
    ref_path = 'config/validator.yaml'
    return nil unless File.exist? ref_path
    config_ref = YAML.load_file ref_path
    config_ref[mode].to_s.strip
  end

  # load config from a YAML file
  def self.load_tester_config
    config_path = get_config_path

    # load config
    if File.exist? config_path
      puts "Using #{self.mode.to_s} config: #{config_path}"
      self.config = YAML.load_file config_path
    else
      self.abort_with_error "#{self.mode.capitalize} config file #{config_path} is missing"
    end

    # check that the config looks right for the current mode
    if self.mode == :supervisor
      if config['port']
        self.abort_with_error <<~HEREDOC
        Error:
        The config file at #{config_path} has a 'port' element, which is not expected when testing a supervisor.
        For supervisor testing, the config should describe the local site used during testing.
        Check that you're using the right config file, or fix the config.
        HEREDOC
      end
    elsif self.mode == :site
      if config['supervisors']
        self.abort_with_error <<~HEREDOC
        Error:
        The config file at #{config_path} has a 'supervisors' element, which is not expected when testing a site.
        For site testing, the config should describe the local supervisor used during testing.
        Check that you're using the right config file, or fix the config.
        HEREDOC
      end
    end

    # components
    self.abort_with_error "Error: config 'components' settings is missing or empty" if config['components'] == {}

    config['main_component'] = config['components']['main'].keys.first rescue {}
    self.abort_with_error "Error: config 'main' component settings is missing or empty" if config['main_component'] == {}

    # timeouts
    self.abort_with_error "Error: config 'timeouts' settings is missing or empty" if config['timeouts'] == {}

    # core version
    core_version =
      ENV['CORE_VERSION'] ||
      config['core_version'] ||
      RSMP::Schema.latest_core_version

    if core_version == 'latest'
      core_version = RSMP::Schema.latest_core_version
    end

    known_versions = RSMP::Schema.core_versions

    # 3.2 will match 3.2.0
    normalized_core_version = known_versions.map {|v| Gem::Version.new(v) }.sort.reverse.detect do |v|
      Gem::Requirement.new(core_version).satisfied_by?(v)
    end

    if normalized_core_version
      config['core_version'] = normalized_core_version.to_s
    else
      self.abort_with_error "Unknown core version #{core_version}, must be one of [#{known_versions.join(', ')}]."
    end
 
    self.load_secrets config_path
  end

  # load auto node config from a YAML file
  # this is the config for the local site/supervisor that will be started for testing
  def self.load_auto_node_config
    auto_node_config_path = get_auto_node_config_path
    return unless auto_node_config_path

    # load auto config
    if File.exist? auto_node_config_path
      puts "Will run auto #{self.mode.to_s} with config: #{auto_node_config_path}"
      self.auto_node_config = YAML.load_file auto_node_config_path
    else
      self.abort_with_error "Auto #{self.mode.to_s} config file #{auto_node_config_path} is missing"
    end
  end

  # get the path of the auto config file
  # First check AUTO_SITE_CONFIG or AUTO_SUPERVISOR_CONFIG environment variables
  # Then look for 'auto_site' or 'auto_supervisor' keys in config/validator.yaml
  def self.get_auto_node_config_path
    # Check environment variable first
    env_key = self.mode == :site ? 'AUTO_SITE_CONFIG' : 'AUTO_SUPERVISOR_CONFIG'
    env_path = ENV[env_key]
    return env_path if env_path && !env_path.empty?
    
    # Fall back to validator.yaml
    ref_path = 'config/validator.yaml'
    return nil unless File.exist? ref_path
    
    config_ref = YAML.load_file ref_path
    key = self.mode == :site ? 'auto_site' : 'auto_supervisor'
    path = config_ref[key].to_s.strip
    path.empty? ? nil : path
  end

  # load secrets
  # secrets can be added directly to the config file in which
  # case no file needs to be loaded.
  # otherwise  look for a path relative to config_path, e.g.
  # if config_path is 'gem_site.yaml', look for 'gem_site_secrets.yaml'
  # if not found, try the the generic path 'secrets.yaml'
  def self.load_secrets config_path
    unless config['secrets']
      basename = File.basename(config_path,'.yaml')
      folder = File.dirname(config_path)
      secrets_path = File.join folder, "#{basename}_secrets.yaml"

      if File.exist?(secrets_path)
        secrets = YAML.load_file(secrets_path)
        config['secrets'] = secrets
      end
    end

    unless self.config.dig 'secrets','security_codes'
      log "Warning: No security code configured".colorize(:yellow)
    else
      unless self.config.dig 'secrets','security_codes',1
        log "Warning: Security code 1 is not configured".colorize(:yellow)
      end
      unless self.config.dig 'secrets','security_codes',2
        log "Warning: Security code 2 is not configured".colorize(:yellow)
      end
    end
  end

  # find out whether we're testing a site or a supervisor,
  # based on the path to the specs we're going to run
  def self.determine_mode files_to_run
    site_folder = './spec/site'
    supervisor_folder = './spec/supervisor'
    site_folder_full_path = File.expand_path(site_folder)
    supervisor_folder_full_path = File.expand_path(supervisor_folder)

    files_to_run.each do |path_str|
      path = Pathname.new(path_str)
      if path.fnmatch?(File.join(site_folder_full_path,'**'))
        self.set_mode :site
      elsif path.fnmatch?(File.join(supervisor_folder_full_path,'**'))
        self.set_mode :supervisor
      else
        self.abort_with_error "Spec #{path_str} is neither a site nor supervisor test"
      end
    end
  end

  # build the tester, which can be a Validator::SiteTester or a Validator::SupervisorTester,
  # depending on what we're going to test
  def self.build_tester
    if self.mode == :site
      Validator::SiteTester.instance = Validator::SiteTester.new
    elsif self.mode == :supervisor
      Validator::SupervisorTester.instance = Validator::SupervisorTester.new
    else
      self.abort_with_error "Unknown test mode: #{self.mode}"
    end
  end

  # build the auto node (local site or supervisor to be tested)
  # this is only done if auto_node_config is loaded
  def self.build_auto_node
    return unless self.auto_node_config

    if self.mode == :site
      self.auto_node = Validator::AutoSite.new
    elsif self.mode == :supervisor
      self.auto_node = Validator::AutoSupervisor.new
    else
      self.abort_with_error "Unknown test mode: #{self.mode}"
    end
  end

  # setup rspec filters to support filtering by RSMP core and SXL version tags
  def self.setup_filters rspec_config
    # enable filtering by rsmp core version tags like '>=3.1.2'
    # Gem::Requirement and Gem::Version classed are used to do the version matching,
    # but this otherwise has nothing to do with Gems
    core_version = Validator.config.dig('core_version')
    if core_version
      core_version = Gem::Version.new core_version
      core_filter = -> (v) {
        !Gem::Requirement.new(v).satisfied_by?(core_version)
      }
      # redefine the inspect method on our proc object,
      # so we get more useful display of the filter option when we
      # run rspec on the command line
      def core_filter.inspect
        "[unless relevant for #{Validator.config.dig('core_version')}]"
      end
      rspec_config.filter_run_excluding core: core_filter
    end

    # enable filtering by sxl version tags like '>=1.0.7'
    # Gem::Requirement and Gem::Version classed are used to do the version matching,
    # but this otherwise has nothing to do with Gems
    sxl_version = Validator.config.dig('sxl_version')
    if sxl_version
      sxl_version = Gem::Version.new sxl_version
      sxl_filter = -> (v) {
        !Gem::Requirement.new(v).satisfied_by?(sxl_version)
      }
      # redefine the inspect method on our proc object,
      # so we get more useful display of the filter option when we
      # run rspec on the command line
      def sxl_filter.inspect
        "[unless relevant for #{Validator.config.dig('sxl_version')}]"
      end
      rspec_config.filter_run_excluding sxl: sxl_filter
    end
  end

  def self.get_config(*path, **options)
    value = Validator.config.dig(*path)
    if value
      value
    else
      path_name = path.inspect

      default = options[:default]
      assume = options[:assume]
      if default
        self.warning "Config #{path_name} not found, using default: #{default}"
        default
      elsif assume
        assume
      else
        raise RuntimeError.new("Config #{path_name} is missing")
      end
    end
  end
end
