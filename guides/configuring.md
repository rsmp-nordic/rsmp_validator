# Configuring
Before you run tests, you must setup a configuration for the equipment you want to tests. 

For example, the validator needs to know the SXL (type of equipment), because the SXL is not send by the equipment when connecting.

## Config files
Configurations are stored as YAML files in the folder `config/`.

The config file contains network settings, timeouts and intervals, list RSMP components, etc. used to run tests.

When you test a site, the config is used to start a local supervisor, using the [rsmp gem](https://github.com/rsmp-nordic/rsmp)).

Similarly, when you test a supervisor, the config is used to start a local site.

Note: The folder `config/private` is ignored by git can can be used for experimenting with configs that you don't want to store in git.

## Choosing what config to use
After creating your test configuration, you need to point the validator to it.

One option is is to use the `config/validator.yaml` file. It's a YAML file, with either a `site` or `supervisor` key, depending on what you're testing. The value should contain the path to your config file.

For example, if you're testing a site, your `.validator.yaml` file might look like this:

```yaml
site: config/ci/my_site_validation_config.yaml
```

You can use the file `config/validator_example.yaml` as a template.

Note: The file `config/validator.yaml` is ignored by git.

The other option is to set either SITE_CONFIG or SUPERVISOR_CONFIG to the path to your config, depending on whether you're testing a site or a supervisor. For example, if you're testing a site, you can run all site test with:

```sh
SITE_CONFIG=config/ci/my_site_validation_config.yaml bundle exec spec/site
```

If the relevant environment variable is set, the file `config/validator.yaml` will not be read.

## Options for Site testing
The config is used to start the local supervisor that will communicate with the site you're, but includes additional options used by the validator, like timeouts and options to restrict what tests to run.

All settings except `components` and `items` can be left out, in which case the default values will be used.

```yaml
port: 13111             # port to listen on
ips: all                # allowed ip addresses. either 'all' or a list
rsmp_versions: all      # allowed core version(s). either 'all' or a list
sxl: tlc                # sxl of the connecting site
intervals:
  timer: 1              # main timer interval (resolution)
  watchdog: 1           # how often to send watchdog messages
  update_date: 0        # requested update rate when subscribing to statuses
timeouts:
  watchdog: 2           # max time bewteen incoming watchdogs
  acknowledgement: 2    # max time until acknowledgement is received
  connect: 1            # max time until site connects
  ready: 1              # max time until site completes connecton sequence
  status_response: 1    # max time until site responds to a status request
  status_update: 1      # max time until site sends a status update
  subscribe: 1          # max time until site sends a status update
  command: 1            # max time until a command results in a status update
  command_response: 1   # max time until site responds to a command request
  alarm: 1              # max time until site raises an alarm
  disconnect: 1         # max time until site disconnects
  shutdown: 1           # max time until site shuts down for a restart
components:             # list of rsmp components, organized by type and name
  main:                 # type
    TC:                 # name. note that this is an (empty) options hash
  signal_group:
    A1:
    A2:
  detector_logic:       
    DL1:
items:                  # other configurations that should be tested
  plans: [1,2]                # list of plans
  traffic_situations: [1,2]   # list of traffic situations
  emergency_routes: [1]       # list of emergency route
  inputs: [1]                 # list of emergency inputs (I/O)
restrict_testing:       # restrict what tests are run, default is to run all
  core_version: 3.1.5   # skip unless relevant for core 3.1.5
  sxl_version: 1.0.13   # skip unless relevant for sxl 1.0.13
secrets:                # place secrets or in a separate file, see below
  security_codes:       # RSMP security codes. there are no defaults for these
    1: '1111'           # level 1
    2: '2222'           # level 2
```

The following settings will be copied into a configuration for the local supervisor: `port`, `sxl`, `intervals`, `timeouts`, `components`, `rsmp_versions`.

The supervisor config will additionaly have `max_sites: 1` and `ips: all` meaning it will allow connections from any ip and with any RSMP site id, but will only allow one site to be connected at a time. Multiple connections will be flagged as an error.

See the [rsmp gem](https://github.com/rsmp-nordic/rsmp) for more details about these settings.

## Options for Supervisor testing
When testing a supervisor, the settings are used by local site settings without modification.

```yaml
# Config for testing a supervisor running on localhost (e.g. one from the rsmp gem)
# The settings are used for starting a local site connecting to the supervisor tested
type: tlc               # type of local site to run
site_id: RN+SI0001      # site id of local site
supervisors:          # what supervisor the local site should connect to
  - ip: 127.0.0.1       # ip
    port: 13111         # port
sxl: tlc                # sxl to use
sxl_version: 1.0.15     # sxl version to use
components:           # components of local site, organized by type and name
  main:                 # type
    TC:                 # name
      cycle_time: 6     # options for component 'TC'
  signal_group:
    A1:
      plan: '11NBBB'
    A2:
      plan: '1NBBBB'
    B1:
      plan: 'BBB11N'
    B2:
      plan: 'BBB1NB'
  detector_logic:
    DL1:
intervals:            # intervals
  timer: 0.1            # basic timer resolution in seconds
  watchdog: 0.1         # time between sending watchdog messages
  reconnect: 0.1        # interval between retries if supervisor is unreachable
timeouts:             # timeouts
  connect: 1            # max time it should take to connect
  ready: 1              # max time to complete handshake sequence
  watchdog: 0.2         # max time between receiving watchdogs
  acknowledgement: 0.2  # max time unless a message we send is acknowledged
restrict_testing:       # restrict what tests are run, default is to run all
  core_version: 3.1.5   # skip unless relevant for core 3.1.5
  sxl_version: 1.0.13   # skip unless relevant for sxl 1.0.13
secrets:                # place secrets or in a separate file, see below
  security_codes:       # RSMP security codes. there are no defaults for these
    1: '1111'           # level 1
    2: '2222'           # level 2
```

## Timeouts
Timeouts should be set as low as possible while, still giving the site time to respond correctly before tests times out and report errors.

## Configuring the actual site/supervisor
You should make sure that the actual site or supervisor you want to test is configured to match the validator configuration file, ie. that the components match and intervals and timeouts are compatible.

When testing a site, you need to configure it to connect to the validator.
This typically includes setting an ip address and port. If the site and the validator is running in the same machine, the ip adress will typically be `localhost` or `127.0.0.1.

When testing a supervisor, you need to configure it to listen for connections on the same port as th validator uses, and make it does reject the connection due to firewalls, ip filtering, or rsmp site id filtering.

RSMP Traffic Light Controllers be default communicate on port 12111, but to avoid interferring with real installations, the validator uses port 13111 by default. You can use another port if you like, just be sure to configure the equipment and the validator to use the same port.

If the site cannot connect to the validator, check the ip and port, and make sure firewalls, etc are not blocking the connection.

## Secrets
Some tests involve commands that require RSMP security codes.

You can place security codes either directly in your config file, or in a separate file.

Note: Files with nnames ending in `_secrets.yaml` are git-ignored.

Secrets have the following structure when in a separate file:

```yaml
security_codes:
  1: '0000'
  2: '0000'
```

