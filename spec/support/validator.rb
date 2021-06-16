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


  def self.set_mode mode
    if self.mode
      if self.mode != mode
        raise "Cannot test run specs for both site and supervisor. Please adjust the list of files/folders"
      end
    else
      if mode == :site
        log "Starting site testing"
        self.mode = mode
      elsif mode == :supervisor
        log "Starting supervisor testing"
        self.mode = mode
      else
        raise "Unknown test mode: #{mode}"
      end
    end
  end

  private

  def self.get_config_path
    key = 'RSMP_VALIDATOR_CONFIG'
    if ENV[key]
      config_path = ENV[key]
    else
      ref_path = '.validator.yaml'
      if File.exist? ref_path
        # get config path
        config_ref = YAML.load_file ref_path
        config_path = config_ref[self.mode.to_s]
      else
        raise "Error: Neither #{ref_path} nor ENV['#{key}'] is present" unless config_path
      end
    end

    raise "Error: Config path #{config_path} is empty" unless config_path
    config_path
  end

  def self.load_config
    config_path = get_config_path

    # load config
    if File.exist? config_path
      self.config = YAML.load_file config_path
    else
      raise "Config file #{config_path} is missing"
    end

    # components
    raise "Warning: config 'components' settings is missing or empty" if config['components'] == {}

    config['main_component'] = config['components']['main'].keys.first rescue {}
    raise "Warning: config 'main' component settings is missing or empty" if config['main_component'] == {}

    # timeouts
    raise "Warning: config 'timeouts' settings is missing or empty" if config['timeouts'] == {}

    # secrets
    # first look for secrets specific to config_path, e.g.
    # if config_path is 'rsmp_gem.yaml', look for 'secrets_rsmp_gem.yaml'
    # if not found, use the generic 'secrets.yaml'
    secrets_name = File.basename(config_path,'.yaml')
    secrets_path = "config/secrets_#{secrets_name}.yaml"
    secrets_path = 'config/secrets.yaml' unless File.exist?(secrets_path)
    self.config['secrets'] = load_secrets(secrets_path)
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
        raise "Spec #{path_str} is neither a site nor supervisor test"
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
