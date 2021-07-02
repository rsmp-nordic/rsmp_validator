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
  def build_node task, options
    klass = case config['type']
    when 'tlc'
      RSMP::Tlc
    else
      RSMP::Site
    end
    @site = klass.new(
      task: task,
      site_settings: config.deep_merge(options),
      logger: Validator.logger,
      collect: options['collect']
    )
  end

  def wait_for_connection
    @proxy = @node.proxies.first
    unless @proxy
      Validator.log "Waiting for connection to supervisor", level: :test
      @proxy = @node.wait_for_supervisor(:any, config['timeouts']['connect'])
    end
    @proxy.wait_for_state :ready, config['timeouts']['ready']
  end

end