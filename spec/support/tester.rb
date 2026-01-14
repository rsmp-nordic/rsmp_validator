# base class for testing either a site or a supervisor
# handles running the corresponding local site/supervisor
# inside an Async reactor

require 'rsmp'
require 'colorize'
require 'rspec/expectations'

class Validator::Tester
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
  def connected(options = {})
    start options, 'Connecting'
    wait_for_proxy
    yield Async::Task.current, @node, @proxy
  end

  # Disconnects the site if connected, then waits until the site is connected
  # before calling the block.
  # Use this if your test specifically needs to start with a fresh connection.
  # But be aware that a fresh connection does not guarantee that the equipment
  # will be in a pristine state. The equipment is not restarted or otherwise
  # reset.
  def reconnected(options = {})
    stop 'Reconnecting'
    start options
    wait_for_proxy
    yield Async::Task.current, @node, @proxy
  end

  # Like `connected`, except that the connection is is closed after the test,
  # before the next test is run.
  # Use this if you somehow modify the RSMP::SiteProxy or otherwise make the
  # current connection unstable or unusable. Because `isolated` closes the
  # connection after the test, you ensure that the modified RSMP::SiteProxy
  # object is discarted and following tests use a new object.
  def isolated(options = {})
    stop 'Isolating'
    start options, 'Connecting'
    wait_for_proxy
    yield Async::Task.current, @node, @proxy
    stop 'Isolating'
  end

  # Disconnects the site if connected before calling the block with a single
  # argument `task`, which is an an Async::Task.
  def disconnected
    stop 'Disconnecting'
    yield Async::Task.current
  end

  # Stop the rsmp supervisor
  def stop(why = nil)
    if @node
      Validator::Log.log why if why
      @node.ignore_errors RSMP::DisconnectError do
        @node.stop
      end
    end
    @node = nil
    @proxy = nil
  end

  private

  def initialize
    parse_config
  end

  # Start the tester, which is either a site or supervisor,
  # depending on what we're testing.
  # The node is run inside an async task that will persist
  # bewteen tests.
  # also run a sentinel task that will listen for sentinel errors
  # notified by the node
  def start(options = {}, _why = nil)
    return if @node

    Validator.reactor.async do |task|
      task.annotate 'node runner'

      @node = build_node options

      Validator.reactor.async do |sentinel|
        sentinel.annotate 'sentinel'
        while @node
          e = @node.error_queue.dequeue
          Validator.log "Sentinel warning: #{e.class}: #{e}", level: :test
          @@sentinel_errors << e
        end
      end

      @node.start # keep running inside the async task
    end
  end

  # Wait until communication has been established, and handshake completed. Subclasses must override
  def wait_for_proxy
    wait_for_connection
    wait_for_handshake
  end

  # Parse config file. Subclasses must override
  def parse_config; end
end
