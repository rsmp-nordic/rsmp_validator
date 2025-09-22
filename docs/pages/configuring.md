---
layout: page
title: Configuration
permalink: /config/
parent: Getting Started
nav_order: 3
---

# Configuration
Before you run tests, you must set up a configuration for the equipment you want to test. 

For example, the validator needs to know the SXL (type of equipment), because the SXL is not sent by the equipment when connecting.

## Config files
Configurations are stored as YAML files in the folder `config/`.

The config file contains network settings, timeouts and intervals, list of RSMP components, etc. used to run tests.

When you test a site, the config is used to start a local supervisor, using the [rsmp gem](https://github.com/rsmp-nordic/rsmp).

Similarly, when you test a supervisor, the config is used to start a local site.

Note: The folder `config/private` is ignored by git and can be used for experimenting with configs that you don't want to store in git.

## Choosing what config to use
After creating your test configuration, you need to point the validator to it.

One option is to use the `config/validator.yaml` file. It's a YAML file, with either a `site` or `supervisor` key, depending on what you're testing. The value should contain the path to your config file.

For example, if you're testing a site, your `validator.yaml` file might look like this:

```yaml
site: config/my_site_validation_config.yaml
```

You can use the file `config/validator_example.yaml` as a template.

Note: The file `config/validator.yaml` is ignored by git.

The other option is to set either SITE_CONFIG or SUPERVISOR_CONFIG to the path to your config, depending on whether you're testing a site or a supervisor. For example, if you're testing a site, you can run all site tests with:

```
SITE_CONFIG=config/my_site_validation_config.yaml bundle exec rspec spec/site
```

If the relevant environment variable is set, the file `config/validator.yaml` will not be read.

## Options for Site testing
The config is used to start the local supervisor that will communicate with the site you're testing, but includes additional options used by the validator, like timeouts and options to restrict what tests to run.

All settings except `components` and `items` can be left out, in which case the default values will be used.

```yaml
port: 13111             # port to listen on
ips: all                # allowed ip addresses. either 'all' or a list. defaults to 'all' if left out
core_version: 3.2.2     # core version of site, tests not relevant for this version will be skipped
sxl: tlc                # sxl of the connecting site, options are 'core' or 'tlc'
sxl_version: 1.2.1      # sxl version of the site, tests not relevant for this version will be skipped
intervals:
  timer: 1              # main timer interval (resolution), in seconds
  watchdog: 1           # how often to send watchdog messages, in seconds

timeouts:
  watchdog: 2           # max time between incoming watchdogs, in seconds
  acknowledgement: 2    # max time until acknowledgement is received, in seconds
  connect: 1            # max time until site connects, in seconds
  ready: 1              # max time until site completes connection sequence, in seconds
  status_response: 1    # max time until site responds to a status request, in seconds
  status_update: 1      # max time until site sends a status update, in seconds
  subscribe: 1          # max time until site sends a status update, in seconds
  command: 1            # max time until a command results in a status update, in seconds
  command_response: 1   # max time until site responds to a command request, in seconds
  alarm: 1              # max time until site raises an alarm, in seconds
  disconnect: 1         # max time until site disconnects, in seconds
  startup_sequence: 5     # max time until startup sequence completes, in seconds
  functional_position: 2  # max time until requested functional position is reached, in seconds
  yellow_flash: 2         # max time until yellow flash is activated, in seconds
  priority_completion: 5  # max time until signal priority request completes, in seconds
  shutdown: 60            # max time until site shuts down, in seconds
components:             # list of rsmp components, organized by type and name
  main:                 # type
    TC:                 # name. note that this is an (empty) options hash
  signal_group:         # list of signal groups to test
    A1:
    A2:
  detector_logic:      # list of detector logics to test
    DL1:
items:                  # other configurations that should be tested
  plans: [1,2]                # list of plans to test
  traffic_situations: [1,2]   # list of traffic situations to test
  emergency_routes: [1]       # list of emergency route to test
  inputs: [1]                 # list of emergency inputs (I/O)
  force_input: 5              # what input to force when testing input forcing
startup_sequence: 'efg' # expected startup sequence
skip_validation:         # list of message types to skip JSON schema validation for
  - Alarm                # example: skip validation for Alarm messages
secrets:                # place secrets or in a separate file, see below
  security_codes:       # RSMP security codes. there are no defaults for these
    1: '1111'           # level 1
    2: '2222'           # level 2
alarm_triggers:          # how to trigger alarms by forcing inputs
  A0302:                # alarm A0302
    input: 7            # can be triggered by forcing input 7
    component: DL1      # and will activate on component DL1
```

The following settings will be copied into a configuration for the local supervisor: `port`, `sxl`, `intervals`, `timeouts`, `components`, `rsmp_versions`, `skip_validation`.

The supervisor config will also have `max_sites: 1` and `ips: all` meaning it will allow connections from any ip and with any RSMP site id, but will only allow one site to be connected at a time. Multiple connections will be flagged as an error.

See the [rsmp gem](https://github.com/rsmp-nordic/rsmp) for more details about these settings.

## Options for Supervisor testing
When testing a supervisor, the settings are used by the local site without modifications.

```yaml
# Config for testing a supervisor running on localhost (e.g. one from the rsmp gem)
# The settings are used for starting a local site connecting to the supervisor tested
type: tlc               # type of local site to run
site_id: RN+SI0001      # site id of local site
supervisors:          # what supervisor the local site should connect to
  - ip: 127.0.0.1       # ip
    port: 13111         # port
core_version: 3.2.2     # core version, tests not relevant for this version will be skipped
sxl: tlc                # sxl to use, options are 'core' or 'tlc'
sxl_version: 1.2.1      # sxl version, tests not relevant for this version will be skipped
components:           # components of local site, organized by type and name
  main:                 # type
    TC:                 # name
  signal_group:       # list of signal groups
    A1:
    A2:
    B1:
    B2:
  detector_logic:     # list of detector logics
    DL1:
signal_plans:         # list of signal plans
  1:                    # signal plan number
    cycle_time: 6         # cycle time
    states:               # signal group states
      A1: '111NBB'          # states per second
      A2: '11NBBB'
      B1: 'BBB11N'
      B2: 'BBB1NB'
    dynamic_bands:        # list of dynamic bands
      1: 0                  # band 1 has the value 0
      2: 5
  2:
    cycle_time: 6
    states:
      A1: 'NNNNBB'
      A2: 'NNNNBN'
      B1: 'BBNNNN'
      B2: 'BNNNNN'
intervals:            # intervals
  timer: 0.1            # basic timer resolution in seconds, in seconds
  watchdog: 0.1         # time between sending watchdog messages, in seconds
  reconnect: 0.1        # interval between retries if supervisor is unreachable, in seconds
  after_connect: 0.2    # delay after connecting before starting handshake, in seconds
timeouts:             # timeouts
  connect: 1            # max time it should take to connect, in seconds
  ready: 1              # max time to complete handshake sequence, in seconds
  watchdog: 0.2         # max time between receiving watchdogs, in seconds
  acknowledgement: 0.2  # max time unless a message we send is acknowledged, in seconds
secrets:                # place secrets or in a separate file, see below
  security_codes:       # RSMP security codes. there are no defaults for these
    1: '1111'           # level 1
    2: '2222'           # level 2
```

## SXL Option
The `sxl` attribute of a configuration specifies what SXL to use for communication. Currently, the valid options are:

- core: Generic RSMP communication. No alarms, commands or status are allowed, only core messages.
- tlc: Traffic Light Controllers.

The sxl will choose the JSON Schema used to validate all ingoing and outgoing messages. It also restricts what type of components can be listed under the `components` attribute in the configuration.

Equipment that doesn't yet have a standardized SXL cannot be fully validated using the RSMP validator, because there are no tests for these types yet, and because there is no JSON Schema to validate the commands and statuses for such types of equipment.

However, you can still use the RSMP Validator to validate the core part of the communication, including connecting, Aggregated Status and Watchdog messages. Use 'core' as the sxl type in the configuration and then run only the tests in the folder `spec/site/core/`. Remember to also set sxl version to the version of the core specification used, e.g. 3.1.5.

## Components Option
RSMP equipment has a list of RSMP components. For example a traffic light controller will have some signal groups and detector logics. In addition all RSMP equipment must have a main component.

To know what to test, your validator configuration must list the components in the equipment under the `components` attribute. Components are organized by type.

For example, here's the component part of a configuration for a traffic light controller with two signal groups, two detector logics, and the main component:

```yaml
components:
  main:                   # type
    KK+AG9998=001TC000:   # component id (a hash, due to the colon)
  signal_group:
    KK+AG9998=001SG001:
    KK+AG9998=001SG002:
  detector_logic:
    KK+AG9998=001DL001:
    KK+AG9998=001DL002:
```

The component ids (e.g. `KK+AG9998=001TC000` in the example above) must match the components in the equipment. Otherwise tests will fail.

Note that each component must be defined as a hash in the YAML file, by using a trailing colon. As the example above shows, the hash will usually be empty. (Items are used to configure components when you run a local RSMP site, e.g. a TLC emulator.)

## Timeouts
Timeouts are defined in seconds. Timeouts should be set as low as possible while still giving the site time to respond correctly before tests time out and report errors.

## Configuring the actual site/supervisor
You should make sure that the actual site or supervisor you want to test is configured to match the validator configuration file, e.g. that the components match and intervals and timeouts are compatible.

When testing a site, you need to configure it to connect to the validator.
This typically includes setting an IP address and port. If the site and the validator are running on the same machine, the IP address will typically be `localhost` or `127.0.0.1`.

When testing a supervisor, you need to configure it to listen for connections on the same port as the validator uses, and make sure the connection is not blocked due to firewalls, IP filtering, or RSMP site ID filtering.

RSMP Traffic Light Controllers by default communicate on port 12111, but to avoid interfering with real installations, the validator uses port 13111 by default. You can use another port if you like, just be sure to configure the equipment and the validator to use the same port.

If the site cannot connect to the validator, check the IP and port, and make sure firewalls, etc. are not blocking the connection.

## Secrets
Some tests involve commands that require RSMP security codes.

You can place security codes either directly in your config file, or in a separate file.

Note: Files with names ending in `_secrets.yaml` are git-ignored.

Secrets have the following structure when in a separate file:

```yaml
security_codes:
  1: '0000'
  2: '0000'
```

## Restricting tests based on Core and SXL version
Usually there is no need to run tests that relate to core or SXL versions newer than what the site or supervisor you're testing is using.

Each test is tagged with the core and SXL version it's relevant for. For example S0027 was added in SXL version 1.0.13, which is why the test for S0027 is tagged with `sxl: '>=1.0.13'`. This means the test is relevant if testing is either unrestricted or restricted to SXL 1.0.13 or higher.

```ruby
specify 'day table is read with S0027', sxl: '>=1.0.13'  do |example|
  Validator::Site.connected do |task,supervisor,site|
    request_status_and_confirm site, "command table",
      { S0027: [:status] }
  end
end
```

The following test runs only if testing is unrestricted or restricted to exactly core version 3.1.5.

```ruby
it 'is correct for rsmp version 3.1.5',  core: '3.1.5' do |example|
  check_sequence '3.1.5'
end
```


Only tests relevant to the core and SXL version specified will be run:

```yaml
core_version: 3.1.2
sxl_version: 1.0.7 
```

In this case, the S0027 test above will not run, because it requires SXL 1.0.13 or higher, but we limited testing to 1.0.7. 

## Auto Node Feature

The validator includes an **auto node feature** that allows you to programmatically start a local site or supervisor to be tested, instead of connecting to external equipment. This is primarily useful when developing the RSMP gem or the validator itself.

Auto nodes create their own logger instance, allowing you to control their output independently. By default, output is interleaved with the validator output using prefixes to distinguish the sources. You can also direct auto node output to a separate file using the `path` option in the auto node's log configuration.

For detailed information about the auto node feature, including configuration, logging options, and usage, see the [Auto Node]({{ site.baseurl}}{% link pages/auto.md %}) page.

To enable it, add `auto_site` or `auto_supervisor` to your `config/validator.yaml`:

```yaml
site: config/gem_tlc.yaml
auto_site: config/simulator/tlc.yaml  # Optional: starts a local site to test
```


