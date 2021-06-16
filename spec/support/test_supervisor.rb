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

  def parse_config 
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
    klass = case config['type']
    when 'tlc'
      RSMP::Tlc
    else
      RSMP::Site
    end
    @site = klass.new(
      task: task,
      site_settings: config.deep_merge(options),
      logger: @logger,
      collect: options['collect']
    )
  end

  def wait_for_connection
    @proxy = @node.proxies.first
    unless @proxy
      log "Waiting for connection to supervisor", level: :test
      @proxy = @node.wait_for_supervisor(:any, config['timeouts']['connect'])
    end
    @proxy.wait_for_state :ready, config['timeouts']['ready']
  end


end