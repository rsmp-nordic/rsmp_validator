---
layout: page
title: Validator::Site
permalink: /test_site/
parent: Writing Tests
---

# Validator::Site helper class

Validator::Site is a helper class for testing RSMP sites in RSpec tests.

Validator::Site uses the `rsmp` gem to run an RSMP supervisor, which the site connects to.

# Connections
The validator performs integration tests of external systems.

To avoid waiting for the site to connect for every test, the supervisor and its connection to the site are usually maintained across tests, unless a test specifically requests otherwise.

Only one site is expected to connect to the supervisor. The first
site connecting will be the one that tests communicate with.

It's recommended to set the maximum number of connected sites in the [supervisor configuration]({{ site.baseurl}}{% link pages/configuring.md %}) to 1. In case a second site tries to connect (or the same site opens multiple connections) the current test will abort and report an error.

## Async
The `rsmp` gem uses the `async` gem to handle concurrency. The supervisor is started inside an Async reactor. To avoid blocking RSpec, the reactor is paused between tests. 

Each RSpec test is run inside a separate Async task.

# Exceptions
Exceptions in your test code will cause the test task to stop, and re-raise the exception outside the reactor so that RSpec sees it.

Exceptions can be caused by timeouts or otherwise be related to your test code.

However, they can also be raised at other times, due to things like RSMP messages that do not conform to expected format. Errors like this will cause the current test to abort and report an error.

# Usage
The class provides a few methods to wait for the site to connect, like `Validator::Site.connected`

Most of these methods take a block of code containing your test code. Once the site is connected, the block will be called:

```ruby
RSpec.describe "Traffic Light Controller" do
  it 'My RSMP test' do |example|
    Validator::Site.connected do |task,supervisor,site|
      # your test code goes here
    end
  end
end
```

Three arguments will be passed to your block:

`task`: an Async::Task
`supervisor`: the RSMP::Supervisor
`site`: an RSMP::SiteProxy, representing the connected site

The `site` object is used to communicate with the site using the interface provided by the `rsmp` gem. For example you can send commands, wait for responses, subscribe to statuses, etc.

Note that these objects all run inside the Async reactor used by the Validator::Site. Therefore you cannot use these objects outside the block, because the reactor is paused.

## Validator::Site.connected
Ensures that the site is connected. If the site is already connected, the block will be called immediately. Otherwise waits until the site is connected before calling the block.

Use this unless there's a specific reason to use one of the other methods. A sequence of tests using `connected` will maintain the current connection to the site without disconnecting/reconnecting, leading to faster testing.

## Validator::Site.reconnected
Disconnects the site if connected, then waits until the site is connected before calling the block.

Use this if your test specifically needs to start with a fresh connection. But be aware that a fresh connection does not guarantee that the equipment will be in a pristine state. The equipment is not restarted or otherwise reset.

## Validator::Site.isolated
Like `connected`, except that the connection is closed after the test, before the next test is run.

Use this if you somehow modify the RSMP::SiteProxy or otherwise make the current connection unstable or unusable. Because `isolated` closes the connection after the test, you ensure that the modified RSMP::SiteProxy object is discarded and following tests use a new object.

## Validator::Site.disconnected
Disconnects the site if connected before calling the block with a single argument `task`, which is an Async::Task.

## Configurations
The TestSite will use the following options from the test [configuration]({{ site.baseurl}}{% link pages/configuring.md %}):

```yaml
timeouts:
    connect: 10    # max seconds to wait for the site to connect
    ready: 10      # max seconds from connection to connection ready
```

The `ready` option is the time from the site connects, until the initial Version messages etc. have been exchanged and you can start sending other messages to the site.



