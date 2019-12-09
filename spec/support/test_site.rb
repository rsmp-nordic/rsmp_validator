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
    task = @reactor.run do |task|
      yield task
    ensure
      # It much faster to use @supervisor.task.stop,
      # but unfortunately that will kills the task after which
      # it does not work anymore. Trying to use the supervisor will
      # result io closed stream errors.
      @reactor.stop
    end
  end

  def start options={}
    unless @supervisor
      log_settings = {
        'active' => true,
        'path' => 'log/validation.log',
        'color' => true,
        'json' => true,
        'acknowledgements' => true,
        'watchdogs' => true
      }

      supervisor_settings = {
        'stop_after_first_session' => true
      }
      @supervisor = RSMP::Supervisor.new(
        supervisor_settings: supervisor_settings,
        log_settings: log_settings
      )
      @supervisor.start
    end

    unless @remote_site
      @remote_site = wait_for_site @supervisor
      @remote_site.wait_for_state :ready, 1
    end
  end

  def stop
    if @supervisor
      @supervisor.stop
    end
    @supervisor = nil
    @remote_site = nil
  end

  def connected options={}, &block
    within_reactor do |task|
      start options
      yield task, @supervisor, @remote_site
    end
  end

  def reconnected options={}, &block
    within_reactor do |task|
      stop
      start options
      yield task, @supervisor, @remote_site
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

  def wait_for_site supervisor
    remote_site = supervisor.wait_for_site(:any,3)
    if remote_site
      remote_site.wait_for_state :ready, 3
      from = "#{remote_site.connection_info[:ip]}:#{remote_site.connection_info[:port]}"
      remote_site
    else
      supervisor.logger.settings['color'] = true
      log = @supervisor.logger.dump @supervisor.archive
      expect(remote_site).not_to be_nil, "Site did not connect:\n#{log}"
    end
  end
end