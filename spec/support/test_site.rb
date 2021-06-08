# Helper class for testing RSMP sites
#
# The class is a singleton g class, meaning there will only ever be 
# one instance.
#
# The class runs an RSMP supervisor (which the site connects to)
# inside an Async reactor. To avoid waiting for the site to connect
# for every test, the supervisor and the connection to the site
# is maintained across test.
#
# However, the reactor is paused between tests, to give RSpec a chance
# 
# Only one site is expected to connect to the supervisor. The first
# site connecting will be the one that tests communicate with.
# 
# to run.
#
# Each RSpec test is run inside a separate Async task.
# Exceptions in you test code will be cause the test task to stop,
# and re-raise the exception ourside the reactor so that RSpec
# sees it.
#
# The class provides a few methods to wait for the site to connect.
# These methods all take a block, which is where you should put
# you test code.
# 
# RSpec.describe "Traffic Light Controller" do
#   it 'my test' do |example|
#     TestSite.connected do |task,supervisor,site|
#       # your test code goes here
#     end
#   end
# end

# The block will pass an RSMP::SiteProxy object,
# which can be used to communicate with the site. For example
# you can send commands, wait for responses, subscribe to statuses, etc.

require 'rsmp'
require 'singleton'
require 'colorize'
require 'rspec/expectations'


class TestSite
  include Singleton
  include RSpec::Matchers
  include RSMP::Logging

  # Ensures that the site is connected.
  # If the site is already connected, the block will be called immediately.
  # Otherwise waits until the site is connected before calling the block.
  # Use this unless there's a specific reason to use one of the other methods.
  # A sequence of test using `connected` will  maintain the current connection
  # to the site without disconnecting/reconnecting, leading to faster testing.
  def connected options={}, &block
    start options, 'Connecting'
    within_reactor do |task|
      wait_for_site
      yield task, @supervisor, @remote_site
    end
  end

  # Disconnects the site if connected, then waits until the site is connected
  # before calling the block.
  #U se this if your test specifically needs to start with a fresh connection.
  # But be aware that a fresh connection does not guarantee that the equipment
  # will be in a pristine state. The equipment is not restart or otherwise be
  # reset.
  def reconnected options={}, &block
    stop 'Reconnecting'
    start options
    within_reactor do |task|
      wait_for_site
      yield task, @supervisor, @remote_site
    end
  end

  # Like `connected`, except that the connection is is closed after the test,
  # before the next test is run.
  # Use this if you somehow modify the RSMP::SiteProxy or otherwise make the
  # current connection unstable or unusable. Because `isolated` closes the
  # connection after the test, you ensure that the modified RSMP::SiteProxy
  # object is discarted and following tests use a new object.
  def isolated options={}, &block
    stop 'Isolating'
    start options, 'Connecting'
    within_reactor do |task|
      wait_for_site
      yield task, @supervisor, @remote_site
    end
    stop 'Isolating'
  end

  # Disconnects the site if connected before calling the block with a single
  # argument `task`, which is an an Async::Task.
  def disconnected &block
    stop 'Disconnecting'
    within_reactor do |task|
      yield task
    end
  end

  # class method that just calls the instance
  def self.connected options={}, &block
    instance.connected options, &block
  end

  # class method that just calls the instance
  def self.reconnected options={}, &block
    instance.reconnected options, &block
  end

  # class method that just calls the instance
  def self.disconnected &block
    instance.disconnected &block
  end

  # class method that just calls the instance
  def self.isolated options={}, &block
    instance.isolated options, &block
  end


  private

  def initialize
    @reactor = Async::Reactor.new
    @logger = RSMP::Logger.new({
      'active' => true,
      'port' => true,
      'path' => LOG_PATH,    # from log_helpers.rb
      'color' => true,
      'json' => true,
      'acknowledgements' => true,
      'watchdogs' => true,
      'test' => true
    })
    initialize_logging logger: @logger
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
        @supervisor.error_condition.wait  # if it's an exception, it will be raised
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

  # Start the rsmp supervisor
  def start options={}, why=nil
    unless @supervisor
      # start the supervisor in a separe async task that will
      # persist across tests
      @supervisor_task = @reactor.async do |task|
        @supervisor = RSMP::Supervisor.new(
          task: task,
          supervisor_settings: SUPERVISOR_CONFIG.merge(options),
          logger: @logger,
          collect: options['collect']
        )
        log why, level: :test if why
        @supervisor.start  # keep running inside the async task, listening for sites
      end
    end

  end

  # Stop the rsmp supervisor
  def stop why=nil
    # will be called outside within_reactor
    # supervisor.stop uses wait(), which requires an async context
    Async do
      if @supervisor
        log why, level: :test if why
        @supervisor.stop
      end
      @supervisor = nil
      @remote_site = nil
    end
  end

  # Wait for an rsmp site to connect to the supervisor
  def wait_for_site
    @remote_site = @supervisor.proxies.first
    unless @remote_site
      log "Waiting for site to connect", level: :test
      @remote_site = @supervisor.wait_for_site(:any, TIMEOUTS_CONFIG['connect'])
    end
    @remote_site.wait_for_state :ready, TIMEOUTS_CONFIG['ready']
  end
end