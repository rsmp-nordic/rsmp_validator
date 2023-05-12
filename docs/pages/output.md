---
layout: page
title: Reporting
permalink: /reporting/
parent: Getting Started
nav_order: 4
---


# Reporting

## RSpec Output Formats
When you run tests, RSpec will report the results.
RSpec has several build-in report formats, including `progress`, `documentation`, `html` and `json`. RSMP Validator comes with two additional formats, called `Brief` and `Details`.

See the [RSpec docs](https://relishapp.com/rspec/rspec-core/v/2-6/docs/command-line/format-option) for more info about formatters.

## Brief format
The `Brief` format is similar to the build-in `documentation` format. It show one line per test, colored according to the test result. But unlike `documentation`, it will include a bit of information about each failing tests directly in the progress overview:

```
Traffic Light Controller
  Clock
    can be read with S0096
    can be set with M0104
    adjusts S0096 status response - Failed: Clock reported by S0096 is off by 24261830s, expected it to be within 2s
    adjusts timestamps of S0096 command response - Failed: Timestamp of S0096 is off by 24261831s, expected it to be within 2s
```

## Detailed format
The `Details` format show a more detailed log of the steps each test performs  as well as all RSMP messages exchanged, with timestamp, port number, etc.

```
Traffic Light Controller / Clock / can be read with S0096
    2021-07-07T13:08:49.347Z                              Starting supervisor on port 13111
> Waiting for site to connect
    2021-07-07T13:08:49.410Z 53786                        Site connected from 127.0.0.1:53786
    2021-07-07T13:08:49.427Z 53786    RN+SI0001     5087  Received Version message for site RN+SI0001 {"mType":"rSMsg","type":"Version","RSMP":[{"vers":"3.1.1"},{"vers":"3.1.2"},{"vers":"3.1.3"},{"vers":"3.1.4"},{"vers":"3.1.5"}],"siteId":[{"sId":"RN+SI0001"}],"SXL":"1.0.15","mId":"50871bcb-57c2-430d-ab0f-49077823d0ac"}
    2021-07-07T13:08:49.457Z 53786    RN+SI0001           Sent MessageAck for Version 5087 {"mType":"rSMsg","type":"MessageAck","oMId":"50871bcb-57c2-430d-ab0f-49077823d0ac"}
```

## Sentinel Warnings
Sometimes invalid messages are received that are not directly related to the currently executing test. For example, alarms or statuses can be received at any time. If such messages do not conform to the RSMP JSON schema, a sentinel warning will be recorded.

The `Brief` and `Details` formats will show sentinel warnings in the summary:

```
Sentinel warnings:

   1) RSMP::SchemaError

      Received invalid Alarm, schema errors: /aSp, enum, , /aS, enum, , /cat, enum, {"mType":"rSMsg","type":"Alarm","mId":"4b844bfd-330e-4d3f-ab69-80417c8d1fbb","ntsOId":"KK+AG9998=001TC000","xNId":"","cId":"KK+AG9998=001SG004","aCId":"A0202","xACId":"C_LAMP_L1_RED (60, 4, 26) : Signal Group #4","xNACId":"","aSp":"issue","ack":"notAcknowledged","aS":"active","sS":"notSuspended","aTs":"2021-07-07T12:30:25.000Z","cat":"b","pri":"3","rvs":[{"n":"color","v":"red"}]}
```


The `Details` formatter will also show sentinel errors as they occur, as part of the datail message log:

```
    2021-07-07T12:30:59.290Z 43286    KK+AG9998=001TC000 4b84  Received invalid Alarm, schema errors: /aSp, enum, , /aS, enum, , /cat, enum, {"mType":"rSMsg","type":"Alarm","mId":"4b844bfd-330e-4d3f-ab69-80417c8d1fbb","ntsOId":"KK+AG9998=001TC000","xNId":"","cId":"KK+AG9998=001SG004","aCId":"A0202","xACId":"C_LAMP_L1_RED (60, 4, 26) : Signal Group #4","xNACId":"","aSp":"issue","ack":"notAcknowledged","aS":"active","sS":"notSuspended","aTs":"2021-07-07T12:30:25.000Z","cat":"b","pri":"3","rvs":[{"n":"color","v":"red"}]}
```

## Choosing output formats
You choose the output format with the `--format` switch (or shorthand `-d`) of the `rspec` command.

```
% bundle exec rspec spec/site --format Validator::Brief
```

By default, the output is printed to the console, but you can redirect it to a file:

```
% bundle exec rspec spec/site --format Validator::Brief --out log/brief.log
```

##  Multiple outputs
RSpec allows you to select several output formats, and direct each one to a separate file. A formatter that's not directed to a file will print to the terminal.

For example, you can show the brief format in the console, and also direct the detailed log to a file with:

```
% bundle exec rspec spec/site --format Validator::Brief --format Validator::Details --out log/validation.log
```

## Default output formats
You can set default options for the rspec command by adding them to the file `.rspec-local`. For example, if you want to show the brief format in the console by default, while directing the detailed log to a file::

```
% cat .rspec-local
--format Validator::Brief
--format Validator::Details --out log/validation.log
```

Now when you run rspec, the output formats will be used automatically and you can just run:

```
% bundle exec rspec
```

You can always override options in `.rspec-local` using options on the command-line.

## Following logs during testing
In case you direct a formatter to a file, you can use the `tail` command in a separate terminal window to view the progress as tests are running:

```
% tail -f log/validation.log
```

## Equipment Log
Typically, the equipment you test also produces one or more internal log files. In case tests fail, it's often useful to have access to these these log files.

## Documenting Test Results
The recommended way to document the result of a test run is to collect the following:

- Validator version, including the specific git commit
- Validator config for the equipment tested
- Version of the equipment, including relevant OS, software and hardware
- Configuration in the equipment
- RSpec output in `Validator::Brief` and `Validator::Details` format.
- Log file(s) from the equipment
