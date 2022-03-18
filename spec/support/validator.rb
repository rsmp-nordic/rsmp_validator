require 'rsmp'
require 'colorize'
require 'rspec/expectations'

module Validator
  include RSpec::Matchers

  class << self
    include RSMP::Logging
    attr_accessor :config, :mode, :logger, :reporter
    attr_accessor :site_validator, :supervisor_validator
  end

  @@reactor = nil

  # get our global reactor
  def self.reactor
    @@reactor
  end

  def self.setup rspec_config
    determine_mode rspec_config.files_to_run
    load_config
    setup_logging rspec_config
    build_testee
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
    reactor.run do |task|
      task.annotate 'rspec'
      example.run
    ensure
      reactor.interrupt
    end
  end

  # initial check that we have a connection to the site/supervisor
  def self.check_connection
    Log.log "Initial #{self.mode} connection check"
    if self.mode == :site
      Validator::Site.testee.connected {}
    elsif self.mode == :supervisor
      Validator::Supervisor.testee.connected {}
    end
    self.log ""
  end

  # log to the rspec formatter
  def self.log str, options={}
    self.reporter.publish :step, message: str
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

      #log "We're testing a #{mode}"
    end
  end

  # get the path of our config file, which depend on whether we're testing a site or supervisor
  def self.get_config_path
    key = "#{self.mode.to_s.upcase}_CONFIG"
    if ENV[key]
      config_path = ENV[key]
    else
      ref_path = 'config/validator.yaml'
      if File.exist? ref_path
        # get config path
        config_ref = YAML.load_file ref_path
        config_path = config_ref[self.mode.to_s].to_s.strip
        self.abort_with_error "Error: #{ref_path} has no :#{self.mode.to_s} key" unless config_path 
      else
        self.abort_with_error "Error: Neither #{ref_path} nor #{key} is present" unless config_path
      end
    end

    self.abort_with_error "Error: Config path is empty" unless config_path && config_path != ''
    config_path
  end

  # load config from a YAML file
  def self.load_config
    config_path = get_config_path

    # load config
    if File.exist? config_path
      #log "Loading config from #{config_path}"
      self.config = YAML.load_file config_path
    else
      self.abort_with_error "Config file #{config_path} is missing"
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

    self.load_secrets config_path
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

  # build the testee, which can Validator::Site or a Validator::Supervisor,
  # depending on what we're going to test
  def self.build_testee
    if self.mode == :site
      Validator::Site.testee = Validator::Site.new
    elsif self.mode == :supervisor
      Validator::Supervisor.testee = Validator::Supervisor.new
    else
      raise "Unknown test mode: #{self.mode}"
    end
  end

  # setup rspec filters to support filtering by RSMP core and SXL version tags
  def self.setup_filters rspec_config
    core_version = Validator.config.dig('restrict_testing','core_version')
    sxl_version = Validator.config.dig('restrict_testing','sxl_version')

    # enable filtering by rsmp core version tags like '>=3.1.2'
    # Gem::Requirement and Gem::Version classed are used to do the version matching,
    # but this otherwise has nothing to do with Gems
    if core_version
      core_version = Gem::Version.new core_version
      core_filter = -> (v) {
        !Gem::Requirement.new(v).satisfied_by?(core_version)
      }
      # redefine the inspect method on our proc object,
      # so we get more useful display of the filter option when we
      # run rspec on the command line
      def core_filter.inspect
        "[unless relevant for #{Validator.config.dig('restrict_testing','core_version')}]"
      end
      rspec_config.filter_run_excluding core: core_filter
    end

    # enable filtering by sxl version tags like '>=1.0.7'
    # Gem::Requirement and Gem::Version classed are used to do the version matching,
    # but this otherwise has nothing to do with Gems
    if sxl_version
      sxl_version = Gem::Version.new sxl_version
      sxl_filter = -> (v) {
        !Gem::Requirement.new(v).satisfied_by?(sxl_version)
      }
      # redefine the inspect method on our proc object,
      # so we get more useful display of the filter option when we
      # run rspec on the command line
      def sxl_filter.inspect
        "[unless relevant for #{Validator.config.dig('restrict_testing','sxl_version')}]"
      end
      rspec_config.filter_run_excluding sxl: sxl_filter
    end
  end
end
