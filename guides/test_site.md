# TestSite helper class

TestSite is a helper class for testing RSMP sites in RSpec test.

TestSite uses the `rsmp` gem to run an RSMP supervisor, which the site connects to.

# Connections
The validator performs integration test of external systems.

To avoid waiting for the site to connect for every test, the supervisor and its connection to the site is usually, maintained across test, unless a test specifically requests otherwise.

Only one site is expected to connect to the supervisor. The first
site connecting will be the one that tests communicate with.

It's recommened to set the maximum number of connected sites in the [supervisor configuration](configuring.md#options) to 1. In case a second site tries to connect (or the same site opens multiple connections) the current test will abort and report an error.

## Async
The `rsmp` gem uses the `async` gem to handle concurrency. The supervisor is started inside an Async reactor. To avoid blocking RSpec, the reactor is paused between tests. 

Each RSpec test is run inside a separate Async task.

# Exceptions
Exceptions in you test code will be cause the test task to stop,
and re-raise the exception ourside the reactor so that RSpec
sees it.

Exceptions can be caused by timeouts or otherwise be related to your test code.

However, they can also be raised at other times, due to things like RSMP message that do not conform to expected format. Errors like this will cause the current test to abort and report an error.

# Usage
The class provides a few methods to wait for the site to connect, like `TestSite.connected`

Most of these methods take a block of code containing you test code. Once the site is connected, the block will be called:

```ruby
RSpec.describe "Traffic Light Controller" do
  it 'My RSMP test' do |example|
    TestSite.connected do |task,supervisor,site|
      # your test code goes here
    end
  end
end
```

Three arguments will be passed to your block:

`task`: an Async::Task
`supervisor`: the RSMP::Supervisor
`site`: an RSMP::SiteProxy, representing the connected site

The `site`object is used to communicate with the site using the interface provided by the `rsmp` gem. For example you can send commands, wait for responses, subscribe to statuses, etc.

Note that these objects all run inside the Async reactor used by the TestSite. Therefore you cannot use these objects outside the block, because the reactor is paused.

## TestSite.connected
Ensures that the site is connected. If the site is already connected, the block will be called immediately. Otherwise waits until the site is connected before calling the block.

Use this unless there's a specific reason to use one of the other methods. A sequence of test using `connected` will  maintain the current connection to the site without disconnecting/reconnecting, leading to faster testing.

## TestSite.reconnected
Disconnects the site if connected, then waits until the site is connected before calling the block.

Use this if your test specifically needs to start with a fresh connection. But be aware that a fresh connection does not guarantee that the equipment will be in a pristine state. The equipment is not restart or otherwise be reset.

## TestSite.isolated
Like `connected`, except that the connection is is closed after the test, before the next test is run.

Use this if you somehow modify the RSMP::SiteProxy or otherwise make the current connection unstable or unusable. Because `isolated` closes the connection after the test, you ensure that the modified RSMP::SiteProxy object is discarted and following tests use a new object.

## TestSite.disconnected
Disconnects the site if connected before calling the block with a single argument `task`, which is an an Async::Task.

## Configurations
The TestSite will use the following options from the test [specification](configuring.md):

```yaml
timeouts:
    connect: 10    # max seconds to wait for the site to connect
    ready: 10      # max seconds from connection to connection ready
```

The `ready` options is the time from the site connects, until the intial Version messages etc. have been exchanged and you can start sending other messages to the site.



