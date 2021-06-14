require 'rsmp'
require 'colorize'
require 'rspec/expectations'

module Validator
  include RSpec::Matchers
  include RSMP::Logging

  class << self
    attr_accessor :config, :testee
  end

  def self.setup
    load_config
    build_testee
  end


  private

  def self.get_config_path
    if ENV['CONFIG']
      config_path = ENV['CONFIG']
    else
      ref_path = '.validator.yaml'
      if File.exist? ref_path
        # get config path
        config_ref = YAML.load_file ref_path
        config_path = config_ref['config']
      else
        raise "Error: Neither #{ref_path} nor ENV['CONFIG'] is present" unless config_path
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

  def self.build_testee
    # a config for a local site will have a config for what supervisor to connect to
    # a local site means we're testing a supervisor
    if self.config['supervisors']
      log "Switching to supervisor testing"
      self.testee = Validator::Supervisor.new
    else
      log "Switching to site testing"
      self.testee = Validator::Site.new
    end
  end
end
