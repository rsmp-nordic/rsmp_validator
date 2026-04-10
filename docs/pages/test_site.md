---
layout: page
title: with_site helper
permalink: /test_site/
parent: Writing Tests
---

# with_site helper

`with_site` is a helper method available in all tests for connecting to an RSMP site.

It uses the `rsmp` gem to run an RSMP supervisor, which the site connects to.

# Connections
The validator performs integration tests of external systems.

To avoid waiting for the site to connect for every test, the supervisor and its connection to the site are usually maintained across tests, unless a test specifically requests otherwise.

Only one site is expected to connect to the supervisor. The first site connecting will be the one that tests communicate with.

It's recommended to set the maximum number of connected sites in the [supervisor configuration]({{ site.baseurl}}{% link pages/configuring.md %}) to 1. In case a second site tries to connect (or the same site opens multiple connections) the current test will abort and report an error.

## Async
The `rsmp` gem uses the `async` gem to handle concurrency. The supervisor is started inside an Async reactor. To avoid blocking sus, the reactor is paused between tests.

Each sus test is run inside a separate Async task.

# Exceptions
Exceptions in your test code will cause the test task to stop, and re-raise the exception so that sus sees it.

Exceptions can be caused by timeouts or otherwise be related to your test code.

However, they can also be raised at other times, due to things like RSMP messages that do not conform to expected format. Errors like this will cause the current test to abort and report an error.

# Usage
Use `with_site` with a state symbol (`:connected`, `:reconnected`, `:isolated`, or `:disconnected`). Once the site is in the requested state, the block will be called:

```ruby
describe "Traffic Light Controller" do
  it 'My RSMP test' do
    with_site(:connected) do |site_proxy|
      # your test code goes here
    end
  end
end
```

One argument is passed to your block:

`site_proxy`: an `RSMP::SiteProxy`, representing the connected site

The `site_proxy` object is used to communicate with the site using the interface provided by the `rsmp` gem. For example you can send commands, wait for responses, subscribe to statuses, etc.

Note that `site_proxy` runs inside the Async reactor. Therefore you cannot use it outside the block, because the reactor is paused between tests.

You can also pass `sxl:` or `core:` keyword arguments to skip the test automatically when the configured version does not match:

```ruby
with_site(:connected, sxl: '>=1.2', core: '>=3.2') do |site_proxy|
  # ...
end
```

## with_site(:connected)
Ensures that the site is connected. If the site is already connected, the block will be called immediately. Otherwise waits until the site is connected before calling the block.

Use this unless there's a specific reason to use one of the other states. A sequence of tests using `:connected` will maintain the current connection to the site without disconnecting/reconnecting, leading to faster testing.

## with_site(:reconnected)
Disconnects the site if connected, then waits until the site is connected before calling the block.

Use this if your test specifically needs to start with a fresh connection. But be aware that a fresh connection does not guarantee that the equipment will be in a pristine state. The equipment is not restarted or otherwise reset.

## with_site(:isolated)
Like `:connected`, except that the connection is closed after the test, before the next test is run.

Use this if you somehow modify the `RSMP::SiteProxy` or otherwise make the current connection unstable or unusable. Because `:isolated` closes the connection after the test, you ensure that the modified proxy object is discarded and following tests use a new one.

## with_site(:disconnected)
Disconnects the site if connected before calling the block. No `site_proxy` argument is passed.

## Configurations
`with_site` will use the following options from the test [configuration]({{ site.baseurl}}{% link pages/configuring.md %}):

```yaml
timeouts:
    connect: 10    # max seconds to wait for the site to connect
    ready: 10      # max seconds from connection to connection ready
```

The `ready` option is the time from when the site connects until the initial Version messages etc. have been exchanged and you can start sending other messages to the site.

