---
layout: page
title: Reporting
permalink: /reporting/
parent: Getting Started
nav_order: 5
---


# Reporting

## Sus Output
When you run tests, sus reports the results. By default sus shows a compact progress indicator and a summary at the end.

## RSMP Log output
RSMP messages exchanged during testing can optionally be logged. Use the `--log` flag with the `rsmp-validator` executable to enable RSMP logging:

```
# Print RSMP log to stdout (interleaved with test output)
% bundle exec rsmp-validator test/site --log

# Write RSMP log to a file
% bundle exec rsmp-validator test/site --log logs/rsmp.log
```

With `--log <path>`, RSMP messages are written to the specified file and sus output continues to the console.

The log shows each RSMP message with timestamp, port number, site id, and the message content:

```
    2021-07-07T13:08:49.347Z                              Starting supervisor on port 13111
> Waiting for site to connect
    2021-07-07T13:08:49.410Z 53786                        Site connected from 127.0.0.1:53786
    2021-07-07T13:08:49.427Z 53786    RN+SI0001     5087  Received Version message for site RN+SI0001 {"mType":"rSMsg","type":"Version",...}
    2021-07-07T13:08:49.457Z 53786    RN+SI0001           Sent MessageAck for Version 5087 {"mType":"rSMsg","type":"MessageAck",...}
```

When using the auto node feature, auto node output is interleaved with the validator's output. Use the `prefix` log option in the auto node config to distinguish between sources.

## Sentinel Warnings
Sometimes invalid messages are received that are not directly related to the currently executing test. For example, alarms or statuses can be received at any time. If such messages do not conform to the RSMP JSON schema, a sentinel warning will be recorded and shown in the test output.

## Following logs during testing
If you direct RSMP logs to a file with `--log <path>`, you can use the `tail` command in a separate terminal window to follow the output as tests are running:

```
% tail -f logs/rsmp.log
```

## Equipment Log
Typically, the equipment you test also produces one or more internal log files. In case tests fail, it's often useful to have access to these these log files.

## Documenting Test Results
The recommended way to document the result of a test run is to collect the following:

- Validator version, including the specific git commit
- Validator config for the equipment tested
- Version of the equipment, including relevant OS, software and hardware
- Configuration in the equipment
- Sus test output
- RSMP log file (if `--log <path>` was used)
- Log file(s) from the equipment
