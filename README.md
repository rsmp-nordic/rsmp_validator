# About
RSMP Validator is a tool for testing RSMP equipment or software. You can use the validator to check that an RSMP implementation is correct and complete, or as assistance during development of an RSMP implementation.

The validator will connect to the equipment or supervisor you want to test, exchange messages and produce a report on what tests succeeded and which failed - and why.

The validator is packaged as the `rsmp-validator` gem. It is written in Ruby, uses the sus test framework, and uses the `rsmp` gem to handle RSMP communication and JSON Schema validation.

Tests are shipped with the gem and run with the `rsmp-validator` executable. The current validator supports RSMP Core 3.3.0 and earlier supported core versions.

# Documentation
See the [detailed documentation](https://rsmp-nordic.github.io/rsmp_validator/).

# Test Hub
The RSMP Validator tests are run daily against a set of Traffic Light Controllers and emulators. The results are published at the RSMP Nordic website [compliance page](https://rsmp-nordic.org/compliance/).

If you're a supplier with equipment that you would like included in our Test Hub, please contact the [RSMP Nordic secretariat](https://rsmp-nordic.org/contact/).

Note: Until the RSMP Validator reaches version 1.0, test results are preliminary.
