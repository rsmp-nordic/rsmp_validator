# Reporting

## RSpec Output
When you run tests, RSpec will produce a report about what tests succeeded/fail. The output is printed to the console, but you can redirect it to a file if you want.

```sh
% bundle exec rspec spec/site > rspec.txt
```

## Validation Log
The validator produces a log detailing the progress of each tests. This log is located in `log/validation.log`.

You can inspect it after a test run, or use a `tail` in a second separate termiman to view the progress as tests are ongoing:

```sh
% tail -f log/validation.log
```

## Equipment Log
Typically, the equipment you test also produces one or more internal log files. In case tests fail, it's often useful to have access to these these log files.

## Documenting Test Results
The recommended way to document the result of a test run is to collect the following:

- Validator version, including the specific git commit
- Validator config for the equipment tested
- Version of the equipment, including relavant OS, software and hardware
- Configuration in the equiqment
- RSpec output
- Validator log at log/validator.log
- Log file(s) from the equipment