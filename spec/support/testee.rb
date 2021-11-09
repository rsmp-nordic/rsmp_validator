# base class for testing either a site or a supervisor
# handles running the corresponding local site/supervisor
# inside an Async reactor

require 'rsmp'
require 'colorize'
require 'rspec/expectations'

class Validator::Testee 
  include RSpec::Matchers

  @@sentinel_errors = []

  def self.sentinel_errors
    @@sentinel_errors
  end

  def config
    Validator.config
  end

  # Ensures that the site is connected.
  # If the site is already connected, the block will be called immediately.
  # Otherwise waits until the site is connected before calling the block.
  # Use this unless there's a specific reason to use one of the other methods.
  # A sequence of test using `connected` will  maintain the current connection
  # to the site without disconnecting/reconnecting, leading to faster testing.
  def connected options={}, &block
    start options, 'Connecting'
    within_reactor do |task|
      wait_for_connection
      yield task, @node, @proxy
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
      wait_for_connection
      yield task, @node, @proxy
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
      wait_for_connection
      yield task, @node, @proxy
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

  # Stop the rsmp supervisor
  def stop why=nil
    # will be called outside within_reactor
    # but stop() requires an async context
    # so run inside an Async block
    Async do
      if @node
        Validator.log why, level: :test if why
        @node.ignore_errors RSMP::DisonnectError do
          @node.stop
        end
      end
      @node = nil
      @proxy = nil
    end
  end
  
  private

  def initialize
    parse_config
    @reactor = Async::Reactor.new
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
        while @node do
          e = @node.error_queue.dequeue
          Validator.log "Sentinel warning: #{e.class}: #{e}", level: :test
          @@sentinel_errors << e
        end
      end
      yield task              # run block until it's finished
    rescue StandardError, RSpec::Expectations::ExpectationNotMetError => e
      error = e               # catch and store errors
    ensure
      @reactor.interrupt      # interrupt reactor
    end

    # reraise errors outside task to surface them in rspec
    if error
      raise error
    end
  end

  # Start the rsmp supervisor
  def start options={}, why=nil
    unless @node
      # start the supervisor in a separe async task that will
      # persist across tests
      @reactor.async do |task|
        @task = task
        @node = build_node task, options
        @node.start  # keep running inside the async task, listening for sites
      rescue StandardError => e
      end
    end
  end

  # Wait for peer to be ready
  def wait_for_connection
  end

  def parse_config
  end
  
end
