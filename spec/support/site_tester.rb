require 'rsmp'
require 'singleton'
require 'colorize'

module RSMP
  class SiteTester
    include Singleton

    def initialize
      @reactor = Async::Reactor.new
      @supervisor = RSMP::Supervisor.new supervisor_settings: { 'log' => { 'active' => false }}
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

    def connected &block
      within_reactor do |task|
        start
        yield task, @remote_site
      end
    end

    def disconnected &block
      within_reactor do |task|
        stop
        yield task
      end
    end

    def self.connected &block
      instance.connected &block
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
end