require 'rsmp'
require 'singleton'
require 'colorize'

class SupervisorRunner
  include Singleton

  def initialize
    @reactor = Async::Reactor.new
    @reactor.async do |task|
      @supervisor = RSMP::Supervisor.new supervisor_settings: { 'log' => { 'active' => false }}
    end
  end

  def within_reactor &block
    @reactor.run do |task|
      yield task
    ensure
      @reactor.stop
    end
  end

  def start
    return if @remote_site
    @supervisor.start
    @remote_site = wait_for_site @supervisor
  end

  def stop
    return unless @remote_site
    @supervisor.stop
    @remote_site = nil
  end

  def with_site &block
    within_reactor do |task|
      start
      yield task, @remote_site
    end
  end

  def without_site &block
    within_reactor do |task|
      stop
      yield task
    end
  end

  def self.with_site &block
    instance.with_site &block
  end

  def self.without_site &block
    instance.without_site &block
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
