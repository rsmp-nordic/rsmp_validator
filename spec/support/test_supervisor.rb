# Experimental:
# Helper class for testing RSMP supervisors 

require 'rsmp'
require 'singleton'
require 'colorize'

class TestSupervisor < Validator

  private

  # load configurations from YAML file
  def load_config 
    # get config path
    validator_config = YAML.load_file '.validator'
    raise "Error: Options file .validator is missing" unless validator_config

    # load config
    rsmp_config_path = validator_config['test_supervisor_config']
    @config = YAML.load_file rsmp_config_path

    puts "Using supervisor test config #{rsmp_config_path}"

    # secrets
    # first look for secrets specific to rsmp_config_path, e.g.
    # if rsmp_config_path is 'rsmp_gem.yaml', look for 'secrets_rsmp_gem.yaml'
    # if not found, use the generic 'secrets.yaml'
    secrets_name = File.basename(rsmp_config_path,'.yaml')
    secrets_path = "config/secrets_#{secrets_name}.yaml"
    secrets_path = 'config/secrets.yaml' unless File.exist?(secrets_path)
    @config['secrets'] = load_secrets(secrets_path)

    # components
    puts "Warning: #{rsmp_config_path} 'components' settings is missing or empty" if @config['components'] == {}

    @config['main_component'] = @config['components']['main'].keys.first rescue {}
    puts "Warning: #{rsmp_config_path} 'main' component settings is missing or empty" if @config['main_component'] == {}

    # timeouts
    puts "Warning: #{rsmp_config_path} 'timeouts' settings is missing or empty" if @config['timeouts'] == {}
  end


  # Resume the reactor and run a block in an async task.
  # A separate sentinel task is used be receive error
  # notifications that should abort the block
  def within_reactor &block
    error = nil

    # use run() to continue the reactor. this will give as a new task,
    # which we run the rspec test inside
    @reactor.run do |task|
      task.annotate 'rspec runner'
      task.async do |sentinel|
        sentinel.annotate 'sentinel'
        @site.error_condition.wait  # if it's an exception, it will be raised
      rescue => e
        error = e
        task.stop
      end
      yield task              # run block until it's finished
    rescue StandardError, RSpec::Expectations::ExpectationNotMetError => e
      error = e               # catch and store errors
    ensure
      @reactor.interrupt      # interrupt reactor
    end

    # reraise errors outside task to surface them in rspec
    if error
      log "Failed: #{error.class}: #{error}", level: :test
      raise error
    else
      log "OK", level: :test
    end
  end

  # build local site
  def build_node task, options
    klass = case @config['type']
    when 'tlc'
      RSMP::Tlc
    else
      RSMP::Site
    end
    @site = klass.new(
      task: task,
      site_settings: @config.deep_merge(options),
      logger: @logger,
      collect: options['collect']
    )
  end

  def wait_for_connection
    @proxy = @node.proxies.first
    unless @proxy
      log "Waiting for connection to supervisor", level: :test
      @proxy = @node.wait_for_supervisor(:any, @config['timeouts']['connect'])
    end
    @proxy.wait_for_state :ready, @config['timeouts']['ready']
  end


end