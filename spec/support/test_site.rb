require 'rsmp'
require 'singleton'
require 'colorize'
require 'rspec/expectations'

class TestSite
  include Singleton
  include RSpec::Matchers

  def initialize
    @reactor = Async::Reactor.new
  end

  def within_reactor &block
    error = nil

    # use run() to continue the reactor. this will give as a new task,
    # which we run the rspec test inside
    more = @reactor.run do |task|
      task.annotate 'test'
      yield task              # run block until it's finished
    rescue StandardError => e
      error = e               # catch and store errors
    ensure
      @reactor.interrupt      # interrupt reactor
    end

    # reraise errors outside task to surface them in rspec
    if error
      @supervisor.log "Failed: #{error.class}: #{error}", level: :test
      raise error
    else
      @supervisor.log "OK", level: :test
    end
  end

  def start options={}, why=nil
    unless @supervisor
      log_settings = {
        'active' => true,
        'port' => true,
        'path' => LOG_PATH,
        'color' => true,
        'json' => true,
        'acknowledgements' => true,
        'watchdogs' => true,
        'test' => true
      }.merge(LOG_CONFIG)

      supervisor_settings = {
        'stop_after_first_session' => false,
        'watchdog_interval' => 5,
        'watchdog_timeout' => 10,
        'acknowledgement_timeout' => 10,
        'command_response_timeout' => 10,
        'status_response_timeout' => 10,
        'status_update_timeout' => 10
      }.merge(RSMP_CONFIG['supervisor'])

      supervisor_settings['sites'][:any]["collect"] = options['collect']

      # start the supervisor in a separe async task that will
      # persist across tests
      @reactor.async do |task|
        @supervisor = RSMP::Supervisor.new(
          task: task,
          supervisor_settings: supervisor_settings,
          log_settings: log_settings,
          collect: options['collect']
        )
        @supervisor.log why, level: :test if why
        @supervisor.start  # keep running inside the async task, listening for sites
      end
    end

  end

  def stop why=nil
    # will be called outside within_reactor
    # supervisor.stop uses wait(), which requires an async context
    Async do
      if @supervisor
        @supervisor.log why, level: :test if @supervisor && why
        @supervisor.stop
      end
      @supervisor = nil
      @remote_site = nil
    end
  end

  def connected options={}, &block
    start options, 'Connecting'
    within_reactor do |task|
      wait_for_site
      yield task, @supervisor, @remote_site
    end
  end

  def reconnected options={}, &block
    stop 'Reconnecting'
    start options
    within_reactor do |task|
      wait_for_site
      yield task, @supervisor, @remote_site
    end
  end

  def disconnected &block
    stop 'Disconnecting'
    within_reactor do |task|
      yield task
    end
  end

  def isolated options={}, &block
    stop 'Isolating'
    start options, 'Connecting'
    within_reactor do |task|
      wait_for_site
      yield task, @supervisor, @remote_site
    end
    stop 'Isolating'
  end

  def self.connected options={}, &block
    instance.connected options, &block
  end

  def self.reconnected options={}, &block
    instance.reconnected options, &block
  end

  def self.disconnected &block
    instance.disconnected &block
  end

  def self.isolated options={}, &block
    instance.isolated options, &block
  end

  def wait_for_site
    @remote_site = @supervisor.find_site :any
    unless @remote_site
      @supervisor.log "Waiting for site to connect", level: :test
      @remote_site = @supervisor.wait_for_site(:any, RSMP_CONFIG['connect_timeout'])
      expect(@remote_site).not_to be_nil, "Site did not connect within #{RSMP_CONFIG['connect_timeout']}s"
    end
    @remote_site.wait_for_state :ready, RSMP_CONFIG['ready_timeout']
  end
end