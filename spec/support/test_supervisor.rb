require 'rsmp'
require 'singleton'
require 'colorize'

class TestSupervisor
  include Singleton
  include ::RSpec::Matchers

  READY_TIMEOUT = 5

  def initialize
    @reactor = Async::Reactor.new
  end

  def within_reactor &block
    task = @reactor.run do |task|
      yield task
    ensure
      # It's much faster to use @site.task.stop,
      # but unfortunately that will kills the task after which
      # it does not work anymore. Trying to use the supervisor will
      # result in closed stream errors.
      @reactor.stop
    end
  end

  def start options={}
    unless @site
      defaults = {
        'log' => {
          'active' => false,
          'color' => true
        },
        'reconnect_interval' => :no,
        'send_after_connect' => false
      }

      site_settings = defaults.merge(options)
      @site = RSMP::Site.new site_settings: site_settings
      @site.start
    end

    unless @remote_supervisor
      @remote_supervisor = @site.proxies.first
      remote_supervisor_state = @remote_supervisor.wait_for_state [:ready,:cannot_connect], READY_TIMEOUT
      expect(remote_supervisor_state).to eq(:ready)
      @remote_supervisor
    end
  end

  def stop
    if @site
      @site.stop
    end
    @site = nil
    @remote_supervisor = nil
  end

  def connected options={}, &block
    within_reactor do |task|
      start options
      yield task, @remote_supervisor, @site
    end
  end

  def reconnected options={}, &block
    within_reactor do |task|
      stop
      start options
      yield task, @remote_supervisor, @site
    end
  end

  def disconnected &block
    within_reactor do |task|
      stop
      yield task
    end
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

  def connect_to_supervisor site
    remote_supervisor = site.connect_to_supervisor(10)
    if remote_supervisor
      remote_supervisor.wait_for_state :ready, 3
      from = "#{remote_supervisor.connection_info[:ip]}:#{remote_supervisor.connection_info[:port]}"
      remote_supervisor
    else
      raise "Timeout while trýing to connect to supervisor".colorize(:red)
    end
  end
end