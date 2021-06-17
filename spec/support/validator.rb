require 'rsmp'
require 'colorize'
require 'rspec/expectations'

module Validator
  include RSpec::Matchers
  include RSMP::Logging

  class << self
    attr_accessor :config, :mode
    attr_accessor :site_validator, :supervisor_validator
  end

  def self.abort_with_error error
    STDERR.puts "Error: #{error}".colorize(:red)
    exit 1
  end

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

      message = "Based on the input files, we're testing a #{mode}"
      puts message
      log message
    end
  end

  private

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

  def self.load_config
    config_path = get_config_path

    # load config
    if File.exist? config_path
      puts "Loading config from #{config_path}"
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
      puts "Warning: No security code configured".colorize(:yellow)
    else
      unless self.config.dig 'secrets','security_codes',1
        puts "Warning: Security code 1 is not configured".colorize(:yellow)
      end
      unless self.config.dig 'secrets','security_codes',2
        puts "Warning: Security code 2 is not configured".colorize(:yellow)
      end
    end
  end

  def self.setup files_to_run
    determine_mode files_to_run
    load_config
    build_testee
  end

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

  def self.build_testee
    if self.mode == :site
      Validator::Site.testee = Validator::Site.new
    elsif self.mode == :supervisor
      Validator::Supervisor.testee = Validator::Supervisor.new
    else
      raise "Unknown test mode: #{self.mode}"
    end
  end

end
