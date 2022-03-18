# Experimental:
# Helper class for testing RSMP supervisors 

require 'rsmp'
require 'singleton'
require 'colorize'

class Validator::Supervisor < Validator::Testee

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

  # build local site
  def build_node options
    klass = case config['type']
    when 'tlc'
      RSMP::TLC::TrafficControllerSite
    else
      RSMP::Site
    end
    @site = klass.new(
      site_settings: config.deep_merge(options),
      logger: Validator.logger,
      collect: options['collect']
    )
  end

  def wait_for_connection
    Log.log "Waiting for connection to supervisor"
    @proxy = @node.wait_for_supervisor(:any, config['timeouts']['connect'])
    @proxy.wait_for_state :ready, timeout: config['timeouts']['connect']
  rescue RSMP::TimeoutError
    raise RSMP::ConnectionError.new "Could not connect to supervisor within #{config['timeouts']['connect']}s"
  end

  def wait_for_handshake
    @proxy.wait_for_state :ready, timeout: config['timeouts']['ready']
  end

end