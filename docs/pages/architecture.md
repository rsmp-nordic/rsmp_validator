---
layout: page
title: Architecture
permalink: /architecture/
nav_order: 1
---

# Architecture
The RSMP Validator is a command-line tool for validating RSMP implementations. It's based on RSpec and tests comes with a suite of tests written in the Ruby language.

The validator performs integration testing, not unit testing. Because it's testing external systems, the equipment is not guaranteed to be in the same state every time you run a test. Most tests therefore start be resetting certain settings in the equipment.

## Overview
The RSMP Validator is based on RSpec, a testing framework written in Ruby. It uses the `rsmp` gem to handle RSMP communication.

The validator includes helper classes that provide an interface to the local RSMP supervisor. This local supervisor can in turn be used to exchange message with the remote RSMP site.

![Overview]({{ site.baseurl }}/assets/images/flow.png "RSMP Validator Flow")


1. Testing is initiated with the `rspec` command. RSpec runs each tests, one after the other.
2. The test uses a helper to wait for the site to connect. The helper will start the local RSMP supervisor if it's not already running.
3. The test uses the RSMP supervisor to send RSMP messages to the site to be tested, e.g. a command request. It will then typically wait for a specific kind of response from the site, e.g. a command response.
4. The site responds with RSMP messages. Responses might be send immediately, or after a while. Responses might include one or more messages.
5. When the supervisor receives a reponse that the test is waiting for, it's passed to the test. The test can then e.g. check that the response is correct. If a response is not received within the defined timeout, the test fails.
6. The test status is reported back to RSpec. RSpec collects results from all tests and generates a report.

## Test Anatomy
Each test is is RSpec _specification_, written in Ruby.

For example, this test verifies that a traffic light controller can be put into yellow flash, and afterwards be but back to normal control:

```ruby
# Verify that we can activate yellow flash
it 'M0001 set dark mode', sxl: '>=1.0.7' do |example|
  Validator::Site.connected do |task,supervisor,site|
    prepare task, site
    switch_yellow_flash
    switch_normal_control
  end
end
```

Helper methods typically sends RSMP mesages and verifies responses. For example, the method `switch_yellow_flash` used above first send an M0001 command and then subscribe to the S0011 status to check that the mode actually switches to yellow flash within a defined time period. Any errors will cause the test to abort and flagged as failed.

For traffic light controllers testing will attempt to change signal plans, force detector logics, restart the controller, etc. It is therefore **not** recommended to test equipment that's in use on street.

## RSMP Connections
The RSMP communication is handled by the [rsmp gem](https://github.com/rsmp-nordic/rsmp).

To speed up testing, the connection will be kept open across tests when possible. However, each tests can specify whether the connection must be closed and reestablished before the test is run. This is useful when testing connection sequence, etc.

## JSON Schema validation
All RSMP messages are checked against the RSMP JSON Schema using the [rsmp_schemer gem](https://github.com/rsmp-nordic/rsmp_schemer) to validate the format, attribute names, etc.

## Concurrency
The validator uses the `rsmp` gem to handle RSMP communication. The `rsmp` gem in turn uses the `async` gem to handle concurrency.

The RSMP supervisor therefore runs inside an Async event-reactor. The reactor must be stopped between test, to give RSpec an option to run and move on to the next test. The TestSite handles pausing and resuming the event reactor between tests.

This [TestSite]({% link pages/test_site.md %}) class handles running the RSMP supervisor that that site connects to, and provides a few methods that that can be used in tests to wait for the site to be connected (or disconnected).

## Background Messages
RSMP is based on TCP sockets, not HTTP. This means that messages can be send in both directions at any time. 

RSMP messages that are not directly related to the currently running tests is often exchanged. For example, watchdog or status messages might be send by the site during testing, and acknowledgements are send back by the supervisor. Such message are typically ignored by the test, because the test will only wait for (and validate) to specific messages related to the current test flow.

