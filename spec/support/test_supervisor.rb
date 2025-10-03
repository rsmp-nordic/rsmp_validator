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

  def initialize
    @programmatic_supervisor = nil
    @supervisor_config = nil
    super
  end

  def parse_config
    super
    
    # load supervisor config if we should start a supervisor programmatically
    if Validator.supervisor_to_test_config_path
      @supervisor_config = YAML.load_file Validator.supervisor_to_test_config_path
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
    Validator::Log.log "Waiting for connection to supervisor"
    @proxy = @node.find_supervisor :any
    begin
      # wait for proxy to be connected (or ready)
      @proxy.wait_for_state [:connected,:ready], timeout: config['timeouts']['connect']
    rescue RSMP::TimeoutError
      raise RSMP::ConnectionError.new "Could not connect to supervisor within #{config['timeouts']['connect']}s"
    end
  end

  def wait_for_handshake
    begin
      # wait for handshake to be completed
      @proxy.wait_for_state :ready, timeout: config['timeouts']['ready']
    rescue RSMP::TimeoutError
      raise RSMP::ConnectionError.new "Handshake didn't complete within #{config['timeouts']['ready']}s"
    end
  end

  # Start a programmatic supervisor if configured
  def start_programmatic_supervisor
    return unless @supervisor_config
    return if @programmatic_supervisor

    Validator::Log.log "Starting programmatic supervisor"

    Validator.reactor.async do |task|
      task.annotate 'programmatic supervisor runner'

      @programmatic_supervisor = RSMP::Supervisor.new(
        supervisor_settings: @supervisor_config,
        logger: Validator.logger
      )

      @programmatic_supervisor.start  # keep running inside the async task
    end
  end

  # Stop the programmatic supervisor if running
  def stop_programmatic_supervisor
    if @programmatic_supervisor
      Validator::Log.log "Stopping programmatic supervisor"
      @programmatic_supervisor.ignore_errors RSMP::DisconnectError do
        @programmatic_supervisor.stop
      end
      @programmatic_supervisor = nil
    end
  end

end
