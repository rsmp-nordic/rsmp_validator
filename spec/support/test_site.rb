# Helper class for testing RSMP sites
#
# The class is a singleton g class, meaning there will only ever be 
# one instance.
#
# The class runs an RSMP supervisor (which the site connects to)
# inside an Async reactor. To avoid waiting for the site to connect
# for every test, the supervisor and the connection to the site
# is maintained across test.
#
# However, the reactor is paused between tests, to give RSpec a chance
# 
# Only one site is expected to connect to the supervisor. The first
# site connecting will be the one that tests communicate with.
# 
# to run.
#
# Each RSpec test is run inside a separate Async task.
# Exceptions in you test code will be cause the test task to stop,
# and re-raise the exception ourside the reactor so that RSpec
# sees it.
#
# The class provides a few methods to wait for the site to connect.
# These methods all take a block, which is where you should put
# you test code.
# 
# RSpec.describe "Traffic Light Controller" do
#   it 'my test' do |example|
#     TestSite.connected do |task,supervisor,site|
#       # your test code goes here
#     end
#   end
# end

# The block will pass an RSMP::SiteProxy object,
# which can be used to communicate with the site. For example
# you can send commands, wait for responses, subscribe to statuses, etc.

class TestSite < Validator

  private

  def load_config    
    # get config path
    validator_config = YAML.load_file '.validator'
    raise "Error: Options file .validator is missing" unless validator_config

    # load config
    rsmp_config_path = validator_config['test_site_config']
    @config = YAML.load_file rsmp_config_path

    # log path
    @config['log'] = @config['log_config_path'] rescue {}


    # secrets
    # first look for secrets specific to rsmp_config_path, e.g.
    # if rsmp_config_path is 'rsmp_gem.yaml', look for 'secrets_rsmp_gem.yaml'
    # if not found, use the generic 'secrets.yaml'
    secrets_name = File.basename(rsmp_config_path,'.yaml')
    secrets_path = "config/secrets_#{secrets_name}.yaml"
    secrets_path = 'config/secrets.yaml' unless File.exist?(secrets_path)
    @config['secrets'] = load_secrets(secrets_path)


    # rsmp supervisor config
    # pick certains elements from the validator @config
    # 
    want = ['sxl','intervals','timeouts','components','rsmp_versions']
    guest_settings = @config.select { |key| want.include? key }
    @config['supervisor'] = {
      'port' => @config['port'],
      'max_sites' => 1,
      'guest' => guest_settings
    }

    # components
    @config['component'] = @config['components'] rescue {}
    puts "Warning: #{rsmp_config_path} 'components' settings is missing or empty" if @config['component'] == {}

    @config['main_component'] = @config['component']['main'].keys.first rescue {}
    puts "Warning: #{rsmp_config_path} 'main' component settings is missing or empty" if @config['main_component'] == {}

    # timeouts
    @config['timeouts'] = @config['timeouts'] rescue {}
    puts "Warning: #{rsmp_config_path} 'timeouts' settings is missing or empty" if @config['timeouts'] == {}

    [
      'connect',
      'ready',
      'status_response',
      'status_update',
      'subscribe',
      'command',
      'command_response',
      'alarm',
      'disconnect',
      'shutdown'
    ].each do |key|
      raise "@config 'timeouts/#{key}' is missing from #{rsmp_config_path}" unless @config['timeouts'][key]
    end

    # timeouts
    @config[:items] = @config['items'] rescue {}

    # scripts
    @config[:script_paths] = @config['supervisor']['scripts']
    if @config[:script_paths]
      puts "Warning: Script path for activating alarm is missing or empty" if @config[:script_paths]['activate_alarm'] == {}
      unless File.exist? @config[:script_paths]['activate_alarm']
        puts "Warning: Script at #{@config[:script_paths]['activate_alarm']} for activating alarm is missing"
      end
      puts "Warning: Script path for deactivating alarm is missing or empty" if @config[:script_paths]['deactivate_alarm'] == {}
      unless File.exist? @config[:script_paths]['deactivate_alarm']
        puts "Warning: Script at #{@config[:script_paths]['deactivate_alarm']} for deactivating alarm is missing"
      end
    end
  end

  # build local supervisor
  def build_node task, options
    RSMP::Supervisor.new(
      task: task,
      supervisor_settings: @config['supervisor'].deep_merge(options),
      logger: @logger,
      collect: options['collect']
    )
  end

  # Wait for an rsmp site to connect to the supervisor
  def wait_for_connection
    @proxy = @node.proxies.first
    unless @proxy
      log "Waiting for site to connect", level: :test
      @proxy = @node.wait_for_site(:any, @config['timeouts']['connect'])
    end
    @proxy.wait_for_state :ready, @config['timeouts']['ready']
  end
end