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
#     Validator::Site.connected do |task,supervisor,site|
#       # your test code goes here
#     end
#   end
# end

# The block will pass an RSMP::SiteProxy object,
# which can be used to communicate with the site. For example
# you can send commands, wait for responses, subscribe to statuses, etc.

class Validator::Site < Validator::Testee

   # class methods that just calls the instance stored in Validator
  class << self
    attr_accessor :testee

    def connected options={}, &block
      testee.connected options, &block
    end

    def reconnected options={}, &block
      testee.reconnected options, &block
    end

    def disconnected &block
      testee.disconnected &block
    end

    def isolated options={}, &block
      testee.isolated options, &block
    end
  end

  def parse_config
    # build rsmp supervisor config by
    # picking elements from the config
    want = ['sxl','intervals','timeouts','components','rsmp_versions']
    guest_settings = config.select { |key| want.include? key }
    @supervisor_config = {
      'port' => config['port'],
      'max_sites' => 1,
      'guest' => guest_settings
    }
    @log_settings = config['log']

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
      raise "config 'timeouts/#{key}' is missing" unless config['timeouts'][key]
    end


    # scripts
    if config['scripts']
      puts "Warning: Script path for activating alarm is missing or empty".colorize(:yellow) if config['scripts']['activate_alarm'] == {}
      unless File.exist? config['scripts']['activate_alarm']
        puts "Warning: Script at #{config['scripts']['activate_alarm']} for activating alarm is missing".colorize(:yellow)
      end
      puts "Warning: Script path for deactivating alarm is missing or empty".colorize(:yellow) if config['scripts']['deactivate_alarm'] == {}
      unless File.exist? config['scripts']['deactivate_alarm']
        puts "Warning: Script at #{config['scripts']['deactivate_alarm']} for deactivating alarm is missing".colorize(:yellow)
      end
    end

  end

  # build local supervisor
  def build_node task, options
    RSMP::Supervisor.new(
      task: task,
      supervisor_settings: @supervisor_config.deep_merge(options),
      logger: @logger,
      collect: options['collect']
    )
  end

  # Wait for an rsmp site to connect to the supervisor
  def wait_for_connection
    @proxy = @node.proxies.first
    unless @proxy
      log "Waiting for site to connect", level: :test
      @proxy = @node.wait_for_site(:any, config['timeouts']['connect'])
    end
    @proxy.wait_for_state :ready, config['timeouts']['ready']
  end
end