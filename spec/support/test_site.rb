require 'rsmp'
require 'singleton'
require 'colorize'

class TestSite
  include Singleton

  def initialize
    @reactor = Async::Reactor.new
  end

  def within_reactor &block
    @reactor.run do |task|
      yield task
    ensure
      Async::Task.current.stop
    end
  end

  def start options={}
   unless @supervisor
    supervisor_settings = { 'log' => { 'active' => false }}.merge(options)
    @supervisor = RSMP::Supervisor.new supervisor_settings: supervisor_settings
    @supervisor.start
    @remote_site = wait_for_site @supervisor
    end
  end

  def stop
    if @supervisor
      @supervisor.stop
      @supervisor = nil
      @remote_site = nil
    end
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
    #puts "Waiting for site...".colorize(:light_blue)
    remote_site = supervisor.wait_for_site(:any,10)
    if remote_site
      remote_site.wait_for_state :ready, 3
      from = "#{remote_site.connection_info[:ip]}:#{remote_site.connection_info[:port]}"
      #puts "Site #{remote_site.site_id} connected from #{from}".colorize(:light_blue)
      remote_site
    else
      raise "Site connection timeout".colorize(:red)
    end
  end
end