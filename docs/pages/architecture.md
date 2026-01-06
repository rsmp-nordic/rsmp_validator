---
layout: page
title: How it Works
permalink: /architecture/
nav_order: 2
---

# How it Works
The RSMP Validator is a command-line tool for validating RSMP implementations. It's based on RSpec with tests written in the Ruby language.

The `rsmp` gem is used to handle RSMP communication.

The validator performs integration testing, not unit testing. The equipment you test is not guaranteed to be in the same state every time you run a test. Most tests therefore start by resetting certain settings in the equipment to a known state.

## Flow
The RSMP Validator consists of RSpec, the individual tests and some helper classes.

When you run tests, a local RSMP supervisor is started, to communicate with the site you're testing. The helper classes provide an interface to the supervisor. This local supervisor can in turn be used to exchange messages with the site you're testing.

![Overview]({{ site.baseurl }}/assets/images/flow.png "RSMP Validator Flow")

1. Testing is initiated with the `rspec` command. RSpec runs each test, one after the other.
2. The test uses a helper to wait for the site to connect. The helper will start the local RSMP supervisor if it's not already running.
3. The test uses the RSMP supervisor to send RSMP messages to the site to be tested, e.g. a command request. It will then typically wait for a specific kind of response from the site, e.g. a command response.
4. The site responds with RSMP messages. Responses might be sent immediately, or after a while. Responses might include one or more messages.
5. When the supervisor receives a response that the test is waiting for, it's passed to the test. The test can then e.g. check that the response is correct. If a response is not received within the defined timeout, the test fails.
6. The test status is reported back to RSpec. RSpec collects results from all tests and generates a report.

## Understanding Tests
Tests are written as RSpec specifications in the Ruby language.

RSpec specifications use [expectations](https://relishapp.com/rspec/rspec-expectations/docs) to check expected outcomes.

### Connecting to the Site
The helper `Validator::Site` is used to wait for a connection to the site:

```ruby
it 'connects' do
  Validator::Site.connected do |task,supervisor,site|
    # site is now connected. ready for testing!
  end
end
```

An RSMP connection is always initiated by the site, not the supervisor. The retry interval can often be several minutes or more. Reestablishing the RSMP connection in each test would therefore be very slow.

To speed up testing `Validator::Site` can keep the RSMP connection open between tests.

The example above uses `Validator::Site#connected`. If the previous test left the connection open, it's reused, otherwise it waits for the site to reconnect.

A test can also use `Validator::Site#reconnected` to request that the RSMP connection is closed and reestablished before continuing with the test, or `Validator::Site#disconnected` to ensure that the connection is closed. See the documentation of the [Validator::Site]({{ site.baseurl}}{% link pages/test_site.md %}) helper for details. 

### Interacting with the Site
`Validator::Site#connected` and friends will return a `site` object which can be used to communicate with the site using the interface provided by the `rsmp` gem. For example you can send RSMP commands, wait for responses, subscribe to statuses, etc.

### Exceptions and Timeouts
Timeouts are essential when testing external systems. When you send a command or request, you expect a response within a certain amount of time.

These timeouts must be defined in the test [configuration]({{ site.baseurl}}{% link pages/configuring.md %}).

When you use the `rsmp` gem to wait for RSMP messages, you must provide a timeout. If the desired message is not received in time, an exception is raised. 

Often, you will not need to include any exception handling in your test code. If an exception is raised, the test will abort and RSpec will catch the error and move on to the next test.

### Configurations
Before running tests, you need to setup a configuration for the equipment you're testing. The configuration defines things like timeouts, RSMP components, etc.

The configuration is stored as a YAML file and loaded into a Ruby object. A test can access the configurations using `Validator.config`. For example, a test might access a specific watchdog timeout using:

```ruby
timeout = Validator.config['timeouts','watchdog']
```

The helper `Validator.get_config` can be used to fetch config values, while providing a default value and stopping if the config is missing. You pass an array of keys, which will be used to fetch the config, and optionally a default value:

```ruby
timeout = Validator.get_config('timeouts','watchdog', default: 5)
```

If the config value is not found, the default will be used if provided, but a warning will be printed.
If the config is not found, and no default is provided, the test will be aborted, showing an error.

In general, default values are not encouraged, as different types of equipment often require different configurations. For this reason, it's usually better not to provide a default value, and instead require that the config is present.

### Logging
During testing, a log is generated by RSpec. It's often useful to print to the log, for example to print information about what steps are being performed by the test. If a test fails, this will make it easier to understand the log file.

```ruby
Validator.log "Checking watchdog timestamp", level: :test
```

### Example
The test below checks that a Traffic Light Controller responds correctly to setting the clock.

First `Validator::Site.connected` is used to wait for a connection.

The helper method `with_clock_set` is then used to send an RSMP command to set the clock in a TLC. 

Then the method `site.collect` is used to to wait for a Watchdog message.

Finally `expect()` is used to check that the timestamp close enough to what we expect, allowing for a bit of inaccuracy due to network lag.

```ruby
RSpec.describe "Traffic Light Controller" do
  include Validator::CommandHelpers
  include Validator::StatusHelpers

  describe 'Clock' do
    CLOCK = Time.new 2020,9,29,17,29,51,'+00:00'

    it 'is used for watchdog timestamp', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        with_clock_set site, CLOCK do
          Validator.log "Checking watchdog timestamp", level: :test
          response = site.collect type: "Watchdog", num: 1, timeout: Validator.get_config('timeouts','watchdog')
          max_diff = Validator.get_config('timeouts','command_response') + Validator.get_config('timeouts','status_response')
          diff = Time.parse(response.attributes['wTs']) - CLOCK
          diff = diff.round
          expect(diff.abs).to be <= max_diff,
            "Timestamp of watchdog is off by #{diff}s, should be within #{max_diff}s"
        end
      end
    end

  end
end
```

Note that there is no code for handling exceptions or errors. Any error will cause the test to abort. The error will be caught and recorded by RSpec.

### Helper methods
Many tests involve similar steps. To avoid duplicating code between tests, the common steps have been factored out as helper methods, located in files in `/spec/support/`.

For example, the method `switch_yellow_flash` first sends an M0001 command and then subscribes to the S0011 status to check that the mode actually switches to yellow flash within a defined time period. Any errors will cause the test to abort and be flagged as failed.

## Concurrency
The validator uses the [`rsmp`](https://github.com/rsmp-nordic/rsmp) gem to handle RSMP communication. To handle concurrency, the `rsmp` gem in turn uses the [`async`](https://github.com/socketry/async) gem, an asynchronous event-driven reactor.

The local RSMP supervisor therefore runs inside an Async reactor. The reactor must be stopped between tests, to give RSpec a chance to run and move on to the next test. The Validator::Site helper handles pausing the event reactor between tests.

It also means that you cannot usually interact with the RSMP site outside the `Validator::Site#connected` block.

## JSON Schema Validation
RSMP is based on TCP sockets, not HTTP. This means that messages can be sent in both directions at any time. 
 
RSMP messages that are not directly related to the currently running test are often exchanged. For example, watchdog or status messages might be sent by the site at any time during a test, and acknowledgements are sent back by the supervisor.

Such messages are typically simply ignored by the test, because the test will only wait for (and validate) specific messages related to the current test flow.

However, all incoming RSMP messages are checked against the RSMP JSON Schema using the [rsmp_schemer gem](https://github.com/rsmp-nordic/rsmp_schemer) to validate the format, attribute names, etc.

If an incoming message is invalid, a **sentinel warning** will be recorded and also noted in the log.

When all tests have run and the test report is generated, sentinel warnings will be included.

All outgoing messages are also checked against the RSMP JSON Schema. If the message is invalid, you will not be able to send it, unless you specifically disable validation.


