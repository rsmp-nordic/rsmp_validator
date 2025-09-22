# About
RSMP Validator is a tool for testing RSMP equipment or software. You can use the validator to check that an RSMP implementation is correct and complete, or as assistance during development of an RSMP implementation.

The validator will connect to the equipment or supervisor you want to test, exchange messages and produce a report on what tests succeeded and which failed - and why.

The validator is based on RSpec and written in Ruby. It uses the `rsmp` gem to handle RSMP communication and the `rsmp_schemer` gem to validate the JSON format of RSMP messages.

Tests are written as RSpec specifications and it's easy to add new tests if needed.

# Documentation
See the [detailed documentation](https://rsmp-nordic.github.io/rsmp_validator/).

# Test Hub
The RSMP Validator tests are run daily against a set of Traffic Light Controllers and emulators. The results are published at the RSMP Nordic website [compliance page](https://rsmp-nordic.org/compliance/).

If you're a supplier with equipment that you would like included in our Test Hub, please contact the [RSMP Nordic secretariat](https://rsmp-nordic.org/contact/).

Note: Until the RSMP Validator reaches version 1.0, test results are preliminary.
