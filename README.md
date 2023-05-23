# About
RSMP Validator is a tool for testing RSMP equipment or software. You can use the validator to check that an RSMP implementation is correct and complete, or as an assistance during development of an RSMP implementation.

The validator will connect to the equipment or supervisor you wan to tests, exchange message and produce a report on what tests succeeded and which failed - and why.

The validator is based on RSpec and written in Ruby. It uses the `rsmp` gem to handle RSMP communication and the `rsmp_schemer` gem to validate the JSON format of RSMP messages.

Test are written as RSpec specifications and it's easy to add new tests if needed.

# Documentation
See the [detailed documentation](https://rsmp-nordic.github.io/rsmp_validator).
