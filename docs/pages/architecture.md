---
layout: page
title: About
permalink: /about/
nav_order: 1
---

# About
The RSMP Validator is a command-line tool for for automated testing of RSMP equipment or systems. It's based on RSpec and tests are written in the Ruby language.

When you run tests, the validator will communicate with equipment via RSMP and go through a set of predefined tests. It will then report the results, which can be used to assess the RSMP compliance and pin-point any problems.

```
% bundle exec rspec spec/site/core spec/site/tlc
Using test config config/gem_tlc.yaml
Run options: exclude {:rsmp=>[unless relevant for 3.1.5], :script=>true}
...............................................................................

Finished in 6.22 seconds (files took 0.60681 seconds to load)
79 examples, 0 failures
```

All tests green!

For traffic light controllers testing will attempt to change signal plans, force detector logics, restart the controller, etc. It is therefore **not** recommended to test equipment that's in use on street.

See also the [overview of RSMP Nordic test tools]({% link pages/tools.md %}).

## What equipment can be tested?
The validator can be used to test all types of RSMP equipment. Traffic Light Controllers have a standardized RSMP Signal Exchange List (SXL), and tests cover all messages in this SXL. For other types of equipment tests cover only the  RSMP Core specification. You can [add you own tests]({% link pages/writing.md %}) if you want.

The validator also includes preliminary support for testing supervisor systems. When testing a supervisor, a local site will be started and it will connect to the supervisor to be tested.

## Do I need to learn the Ruby langauge?
No. You can use the validator without writing any Ruby code. Ruby is only needed if you want to modify or add tests, or you want runderstand more in-depth how specific tests work.

## How it Works
A RSMP supervisor will be started by the validator and the site is expected to connect to it. 

Once the site has connected, tests will be run to validate aspects like connection sequence, commmands, alarms, etc.

To speed up testing, the connection will be kept open across tests when possible. However, tests specify whether the connection must be closedd and reestablished before the test is run. This is useful when testing connection sequence, etc.

When you test a site, the validator starts an local RSMP supervisor and waits for the equipment to connect. 

Once the connection has been established, each tests will send and wait for messages in a predefined manner. A number of checks will be performed on the exchanged messages to ensure that the equipment implements the RSMP specification correctly.

The validator performs integration testing, not unit testing. Because you're testing external systems, the equipment is not guaranteed to be in the same state every time you run a test.

Each test is written in Ruby as a RSpec specification. A number of helpers are available to make it easy to [write tests]({% link pages/writing.md %}).

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

The RSMP communication is handled by the [rsmp gem](https://github.com/rsmp-nordic/rsmp), and for format of RSMP messages is checked by the [rsmp_schemer](https://github.com/rsmp-nordic/rsmp_schemer) gem.

