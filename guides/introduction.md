# Introduction
The RSMP Validator is a command-line tool for for automated testing of RSMP equipment or systems. It's based on RSpec and tests are written in the Ruby language.

When you run tests, the validator will communicate with equipment via RSMP and go through a set of predefined tests. It will then report the results, which can be used to assess the RSMP compliance and pin-point any problems.

```sh
% bundle exec rspec spec/site/core spec/site/tlc
Using test config config/ci/rsmp_gem.yaml
Run options: exclude {:rsmp=>[unless relevant for 3.1.5], :script=>true}
...............................................................................

Finished in 6.22 seconds (files took 0.60681 seconds to load)
79 examples, 0 failures
```

All tests green!

## What equipment can be tested?
The validator can be used to test all types of RSMP equipment. Traffic Light Controllers has a standardized RSMP Signal Exchange List (SXL), and tests cover all messages in this SXL. For other types of equipment tests cover only the general RSMP Core specificationl. You can add you own tests if you want.

You will typically use the validator in a lab/office setup. The validator will send many diffrent commands to the equipment during tests. For traffic light controllers test will attempt to change signal plans, force detector logics, restart the controller, etc. It is therefore **not** recommended to test euqipment while in use on street.

## Can I test a Supervisor System?
Yes, but it's still [experimental](supervisors.md).

## Do I need to learn the Ruby langauge?
No. You can use the validator without writing any Ruby code. Ruby is only needed if you want to modify or add tests, or you want runderstand more in-depth how specific tests work.

## How does it work?
When you run tests, the validator starts an local RSMP supervisor and waits for the equipment to connect. The validator then sends message to the equipment and wait for responses. A number of checks will be performed on the exchanged messages to ensure that the equipment implements the RSMP specification correctly.

The validator performs integration tests. Because you're testing external systems, the equipment is not guaranteed to be in the same state every time you run a test.

Each test is written in Ruby as a RSpec specification. A number of helpers are available to make it easy to write tests.

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

Helper methods tyically sends RSMP mesages and verifies responses. For example, the method `switch_yellow_flash` used above first send an M0001 command and then subscribe to the S0011 status to check that the mode actually switches to yellow flash within a defined time period. Any errors will cause the test to abort and flagged as failed.

The RSMP communication is handled by the [rsmp gem](https://github.com/rsmp-nordic/rsmp), and for format of RSMP messages is checked by the [rsmp_schemer](https://github.com/rsmp-nordic/rsmp_schemer) gem.

## Guides
More detailed guides on how to use the validator:

- The first step is to [install the validator](installing.md)
- You should then [setup configurations](configuring.md)
- Now you're ready to [run tests](testing.md)
- Read about [documenting results](reporting.md)
- Read about [customizing or adding tests](writing_tests.md)
- Learn about [how it works](implementation.md)

## Other Resources
View the online [documentation of tests](https://rsmp-nordic.github.io/rsmp_validator/index.html).

View the RSMP specifiation for [Core](https://github.com/rsmp-nordic/rsmp_core) or [Traffic Light Controllers ](https://github.com/rsmp-nordic/rsmp_sxl_traffic_lights).

If you want a application with a graphical user interface for manually sending and inspecting RSMP message, take a look at the [RSMP Simulator](https://github.com/rsmp-nordic/rsmp_simulator) appplication for Windows.

The RSMP Validator is maintained by [RSMP Nordic](https://rsmp-nordic.org).

See all [RSMP Nordic repositories] on GitHub (https://github.com/rsmp-nordic).

