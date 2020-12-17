require 'rsmp'
require 'singleton'
require 'colorize'
require 'rspec/expectations'

class TestSite
  include Singleton
  include RSpec::Matchers

  LOG_PATH = 'log/validation.log'

  def initialize
    @reactor = Async::Reactor.new
  end

  def self.log_test_header example
    File.open(LOG_PATH, 'a') do |file|
      file.puts "\nRunning test #{example.metadata[:location]} - #{example.full_description}".colorize(:light_black)
    end
  end

  def within_reactor &block
    error = nil

    # use run() to restart the reactor. this will give as a new task,
    # which we can use to run a test in
    task = @reactor.run do |task|
      task.annotate 'test'
      yield task              # run block until it's finished
    rescue StandardError => e
      error = e               # catch and store errors
    ensure
      # It much faster to use @supervisor.task.stop,
      # but unfortunately that will kill the task after which
      # it does not work anymore. Trying to use the supervisor will
      # result io closed stream errors.
      @reactor.stop           # stop reactor, and exit block
    end

    # reraise errors outside task to surface them in rspec
    if error
      @supervisor.log error.to_s, level: :test
      raise error
    end
  end

  def start options={}
    unless @supervisor
      log_settings = {
        'active' => true,
        'path' => LOG_PATH,
        'color' => true,
        'json' => true,
        'acknowledgements' => true,
        'watchdogs' => true,
        'test' => true
      }

      supervisor_settings = {
        'stop_after_first_session' => false,
        'watchdog_interval' => 5,
        'watchdog_timeout' => 10,
        'acknowledgement_timeout' => 10,
        'command_response_timeout' => 10,
        'status_response_timeout' => 10,
        'status_update_timeout' => 10
      }

      # start the supervisor in a separe async task that will
      # persist across tests
      @reactor.async do |task|
        @supervisor = RSMP::Supervisor.new(
          task: task,
          supervisor_settings: supervisor_settings.merge(RSMP_CONFIG['supervisor']),
          log_settings: log_settings.merge(LOG_CONFIG)
        )
        @supervisor.start  # keep running inside the async task, listening for sites
      end
    end

  end

  def stop
    # will be called outside within_reactor
    # supervisor.stop uses wait(), which requires an async context
    Async do
      if @supervisor
        @supervisor.stop
      end
      @supervisor = nil
      @remote_site = nil
    end
  end

  def connected options={}, &block
    start options
    within_reactor do |task|
      wait_for_site
      yield task, @supervisor, @remote_site
    end
  end

  def reconnected options={}, &block
    stop
    start options
    within_reactor do |task|
      wait_for_site
      yield task, @supervisor, @remote_site
    end
  end

  def disconnected &block
    stop
    within_reactor do |task|
      yield task
    end
  end

  def isolated options={}, &block
    stop
    start options
    within_reactor do |task|
      wait_for_site
      yield task, @supervisor, @remote_site
    end
    stop
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
      if @remote_site
        from = "#{@remote_site.connection_info[:ip]}:#{@remote_site.connection_info[:port]}"
      else
        @supervisor.logger.settings['color'] = false
        @supervisor.logger.settings['debug'] = false
        @supervisor.logger.settings['statistics'] = false
        log = @supervisor.logger.dump @supervisor.archive
        expect(@remote_site).not_to be_nil, "Site did not connect:\n#{log}"
      end
    end
    @remote_site.wait_for_state :ready, RSMP_CONFIG['ready_timeout']
  end
end