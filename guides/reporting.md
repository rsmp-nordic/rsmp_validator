# Reporting

## RSpec Output Formats
When you run tests, RSpec will produce a report about what tests succeeded/fail. RSpec has several build-in report formats, including `progress`, `documentation`, `html` and `json`.

The build-in formats are all useful, but the RSMP Validator comes with two additional formatters, `Brief` and `Details`, that shows additional RSMP-related information.

## Brief format
The `Brief` format is similar to the build in `documentation`, and show one line per test, colored according to the test result. However failing test show the error that occured.

```
Traffic Light Controller
  Clock
    can be read with S0096
    can be set with M0104
    adjusts S0096 status response - Failed: Clock reported by S0096 is off by 24261830s, expected it to be within 2s
    adjusts timestamps of S0096 command response - Failed: Timestamp of S0096 is off by 24261831s, expected it to be within 2s
```

# Detailed format
The `Details` format show a more detailed log of the steps each test performs  as well as all RSMP messages exchanged.

```
Traffic Light Controller / Clock / can be read with S0096
    2021-07-07T13:08:49.347Z                              Starting supervisor on port 13111
> Waiting for site to connect
    2021-07-07T13:08:49.410Z 53786                        Site connected from 127.0.0.1:53786
    2021-07-07T13:08:49.427Z 53786    RN+SI0001     5087  Received Version message for site RN+SI0001 {"mType":"rSMsg","type":"Version","RSMP":[{"vers":"3.1.1"},{"vers":"3.1.2"},{"vers":"3.1.3"},{"vers":"3.1.4"},{"vers":"3.1.5"}],"siteId":[{"sId":"RN+SI0001"}],"SXL":"1.0.15","mId":"50871bcb-57c2-430d-ab0f-49077823d0ac"}
    2021-07-07T13:08:49.457Z 53786    RN+SI0001           Sent MessageAck for Version 5087 {"mType":"rSMsg","type":"MessageAck","oMId":"50871bcb-57c2-430d-ab0f-49077823d0ac"}
```


## Choosing output formats
You choose the output format usign the `--format` switch (or shorthand `-d`). The output is printed to the console be default:

```sh
% bundle exec rspec spec/site --format Brief
```

##  Multiple outputs
RSpec allows you to select several output formats, and direct each one to the console or to a separate file as you like. For example, you can show the brief format in the console, and direct the detailed log to a file using:

```sh
% bundle exec rspec spec/site --format Brief --format Details --out log/validation.log
```

## Default output outputs
You can set default options for the rspec command by adding them to the file `.rspec-local`. For example, if you want to show the brief format in the console by default, while directing the detailed log to a file::

```sh
% cat .rspec-local
--format Brief
--format Details --out log/validation.log
```

Now when you run rspec, the output formats will be used automaticallly and you can just run:

```sh
% bundle exec rspec
```

You can always override options in `.rspec-local` using options on the command-line.

# Following logs during testing
In case you direct a formatter to a file, you can use the `tail` command in a separate termimal window to view the progress as tests are running:

```sh
% tail -f log/validation.log
```

## Sentinel Warnings
Sometimes invalid messsage are received that are not direcly related to the currently executing test. For example, alarms or statuses can be received at any time. If such messages do not conform to the RSMP JSON schema, a sentinal warning will be recorded.

Both the `Brief` and `Details` formatters will show sentinel warnings as part of the summary.

The `Details` formatter will also show sentinel errors as they occur.

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