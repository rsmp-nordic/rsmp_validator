# Configuring
Before you run tests, you must setup a configuration for the equipment you want to tests. 

For example, the validator needs to know the SXL (type of equipment), because the SXL is not send by the equipment when connecting.

Configurations are stored as YAML files in the folder `config/`.

Note: The folder `config/private` is ignored by git can can be used for experimenting with configs that you don't want to store in the git.

## Choosing what config file the validator uses
The validator will read the file `config/validator.yaml` to choose what config to use. If not found it will default to `config/rsmp_gem.yaml`, which is suited for running tests against a [Ruby TLC emulator](https://github.com/rsmp-nordic/rsmp)) running on your local machine.

To use another config, copy `config/validator_example.yaml` into a new file file `config/validator.yaml`, and edit it to point to the relevant config file, e.g.:

```yaml
rsmp_config_path: config/my_equipment.yaml
```

Note: The file `config/validator.yaml` is ignored by git.

## Options
The configuration describes the equipment/system that you want to test. Timeouts should be set as low as possible while, still giving the site time to respond correctly before tests times out and report errors.

Test configurations are written in the YAML format and have the following structure and default values. All settings except `components` and `items` can be left out, in which case the default values will be used.

```yaml
port: 13111             # port to listen on
ips: all                # allow ip addresses. either 'all' or a list
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
    B1:
    B2:
  detector_logic:       
    DL1:
items:                  # other configurations that should be tested
  plans: [1,2]                # list of plans
  traffic_situations: [1,2]   # list of traffic situations
  emergency_routes: [1]       # list of emergency route
  inputs: [1]                 # list of emergency inputs (I/O)
```

Certain settings will be copied into a configuration for the RSMP supervisor started by the validator, including: port, sxl, intervals, timeouts, components, rsmp_versions. See the [rsmp gem](https://github.com/rsmp-nordic/rsmp) for more details about these settings.

The supervisor config will additionaly have `max_sites: 1` and `ips: all` meaning it will allow connections from any ip and with any RSMP site id, but will only allow one site to be connected at a time. Multiple connections will be flagged as an error.

## Configuring the site
You should make sure that the site configuration matches the validator configuration file, ie. that the components match and intervals and timeouts are compatible.

## Configuring network
You need to configure the site to connect to the validator.
This typically includes setting an ip address and port. If the site and the validator is running in the same machine, the ip adress will typically be `localhost` or `127.0.0.1.

RSMP Traffic Light Controllers be default communicate on port 12111, but to avoid interferring with real installations, the validator uses port 13111 by default. You can use another port if you like, just be sure to configure the equipment and the validator to use the same port.

If the site cannot connect to the validator, check the ip and port, and make sure firewalls, etc are not blocking the connection.

## Security Codes
Some tests require security codes to run. Place these in config/secrets.yaml, in this format:

```yaml
security_codes:
  1: '0000'
  2: '0000'
```

The file config/secrets.yaml is gitignored and should not be added to the repository.

