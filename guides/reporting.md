# Reporting

## RSpec Output Formats
When you run tests, RSpec will produce a report about what tests succeeded/fail. RSpec has several build-in report formats, including `progress`, `documentation`, `html` and `json`.

The build-in formats are all useful, but the RSMP Validator comes with two additional formatters: `Brief` and `Details`.

The `Brief` format is similar to the build in `documentation`, and show one line per test, colored according to the test result. However failing test show the error that occured.

The `Details` format show a more detailed log of the steps each tests perform as well as all RSMP messages exchanged.

You choose the output format usign the `--format` switch (or shorthand `-d`). The output is printed to the console be default:

```sh
% bundle exec rspec spec/site --format Brief
```

## Sentinel warnings
Sometimes invalid messsage are received that are not direcly related to the currently executing test. For example, alarms or statuses can be received at any time. If such messages do not conform to the RSMP JSON schema, a sentinal will record the errors. Both the `Brief` and `Details` formatters will show sentinel warnings at the final summary. The `Details` formatter will also show the errors as they occur.

## Multiple output formats
Rspec allows you to select several output formats, and direct each one to the console or to a separate file. For example, you can show the brief format in the console, and direct the detailed log to a file using:

```sh
% bundle exec rspec spec/site --format Brief --format Details --out log/validation.log
```

## Default output outputs
You can set default options for rspec by adding them to the file `.rspec-local`. For example, if you want to show the brief format in the console by default, while directing the detailed log to a file using:

``sh
% cat .rspec-local
--format Brief
--format Details --out log/validation.log
``

Now when you run rspec, the output formats will be used automaticallly and you can just run:

``sh
% bundle exec rspec
``

You can always override options in `.rspec-local` using options on the command-line.

# Following logs during testing
In case you direct a formatter to a file, you can use the `tail` command in a separate termimal window to view the progress as tests are running:

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
- RSpec output in `Brief` and `Details` format.
- Log file(s) from the equipment