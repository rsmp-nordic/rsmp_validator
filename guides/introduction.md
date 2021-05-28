# Introduction
## Overview
The RSMP Validator is a test system based on RSpec and written in the Ruby language, which can be used for automated testing of RSMP equipment or systems.

The validator currently has tests covering:

1. The RSMP Core specification, which is common to all types of equipemnt. These tests can therefore be run against all RSMP implementations, and cover basic things like connecting, watchdog messages, aggregated and status.

2. The SXL (Signal Exchange List) for Traffic Light Controllers. These tests are only relevant for testing Traffic Light Controllers, or other equipment that closely follow the same SXL, like som types of traffic counters.

When you run tests, the validator waits for the equipment to connect. The validator then sends message and wait for responses. A number of checks will be performed on the received messages to ensure that the equipment implements the RSMP specification correctly.

IMPORTANT: During testing, the validator will send many different commands to the equipment. For traffic light controllers this include commands to change signal plans, force detector logics, restart the controller, etc. For this reason you should **not** use the validator to test equipment that is in use on street.

## Guides
The first step is to [install the validator](installing.md)

You should then [setup configurations](configuring.md)

Now you're ready to [run tests](testing.md)

Read about [documenting results](reporting.md)

Read about [customizing or adding tests](customizing.md)

Learn about [how it works](implementation.md)

## Other Resources
View the online [documentation of tests](https://rsmp-nordic.github.io/rsmp_validator/index.html).

View the RSMP specifiation for [Core](https://github.com/rsmp-nordic/rsmp_core) or [Traffic Light Controllers ](https://github.com/rsmp-nordic/rsmp_sxl_traffic_lights).

If you want a Desktop for manually sending and inspecting RSMP message, take a look at the [RSMP Simulator](https://github.com/rsmp-nordic/rsmp_simulator) appplication for Windows.

The RSMP Validator is maintained by [RSMP Nordic](https://rsmp-nordic.org).

See all [RSMP Nordic repositories] on GitHub (https://github.com/rsmp-nordic).

