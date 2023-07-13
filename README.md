# About
RSMP Validator is a tool for testing RSMP equipment or software. You can use the validator to check that an RSMP implementation is correct and complete, or as an assistance during development of an RSMP implementation.

The validator will connect to the equipment or supervisor you wan to tests, exchange message and produce a report on what tests succeeded and which failed - and why.

The validator is based on RSpec and written in Ruby. It uses the `rsmp` gem to handle RSMP communication and the `rsmp_schemer` gem to validate the JSON format of RSMP messages.

Test are written as RSpec specifications and it's easy to add new tests if needed.

# Documentation
See the [detailed documentation](https://rsmp-nordic.github.io/rsmp_validator/).

# Test Hub
The RSMP Validator tests are run daily against a set of Traffic Light Controllers and emulators. Here's the latest status.

[![Gem TLC](https://github.com/rsmp-nordic/rsmp_validator/actions/workflows/gem_tlc.yml/badge.svg?branch=master&event=push)](https://github.com/rsmp-nordic/rsmp_validator/actions/workflows/gem_tlc.yml)
[![Dynniq EC-2](https://github.com/rsmp-nordic/rsmp_validator/actions/workflows/dynniq_ec2.yml/badge.svg?branch=master&event=schedule)](https://github.com/rsmp-nordic/rsmp_validator/actions/workflows/dynniq_ec2.yml)
[![Swarco ITC-2](https://github.com/rsmp-nordic/rsmp_validator/actions/workflows/swarco_itc2.yml/badge.svg?branch=master&event=schedule)](https://github.com/rsmp-nordic/rsmp_validator/actions/workflows/swarco_itc2.yml)
[![Swarco ITC-3](https://github.com/rsmp-nordic/rsmp_validator/actions/workflows/swarco_itc3.yml/badge.svg?branch=master&event=schedule)](https://github.com/rsmp-nordic/rsmp_validator/actions/workflows/swarco_itc3.yml)

Note: Until the RMSP Validator reaches version 1.0, test results are preliminary.

If you're a supplier with  equipment that you would like included in our Test Hub, please contact the [RSMP Nordic secretariat](https://rsmp-nordic.org/contact/).
