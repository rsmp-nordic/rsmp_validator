# Configuring
Before you run test, you must setup a configuration for the equipment you want to tests. 

For example, the validator needs to know the SXL (type of equipment), because the SXL is not send by the equipment when connecting.

Configurations are stored as YAML files in the folder `config/`.

Note: The folder `config/private` is ignored by git can can be used for experimenting with configs that you don't want to store in the git.

## Choosing what config file the validator uses
The validator will read the file `config/validator.yaml` to choose what config to use. If not found it will default to `config/rsmp_gem.yaml`, which is suited for running tests against a [Ruby TLC emulator](https://github.com/rsmp-nordic/rsmp)) running on your local machine.

To use another config, copy `config/validator_example.yaml` into a new file file `config/validator.yaml`, and edit it to point to the relevant config file, e.g.:

```yaml
rsmp_config_path: config/ci/my_equipment.yaml
```

Note: The file `config/validator.yaml` is ignored by git.

## Content of config files

supervisor: # config used by the rsmp supervisor started by the validator
  sites:      # settings for sites that connect to the supervisor
     # a supervisor can have different settings for different connecting site, but
     # settings under the :anykey will be used for any site that connect.
     # in a test setup, we usually only expect single site to connect, so using
     # :any is easier that specifying an ip address
    :any:
      # the rsmp core versions that we accept. here we accept only 3.1.2. if the site
      # does not support 3.1.2 the connection will fail, so you need to make sure
      # you're using configs that match the site
      rsmp_versions:
        - 3.1.2
      # list of plans available in the tlc
      # when testing signal plan commands, the validator will try to switch to each of these in turn
      plans:           
        - 3
        - 4
      traffic_situations:  # list of traffic situations available in the tlc
        - 1
        - 2
      emergency_routes:  # list of emergency routes available in the tlc
        - 1
      # list of components. the ids must match what's present in the site,
      # because they are used when sending commands to the site
      # main, signal_group and detector_logic are predefined types, and the only types
      # allowed here in the config
      components:
        main:   # type
          KK+AG9998=001TC000:   # id
        signal_group:
          KK+AG9998=001SG001:
        detector_logic:
          KK+AG9998=001DL001:
  
  # timeouts and intervals in seconds
  # set this as low as possible to make tests run faster,
  # while still giving the equipment reasonable time to respond
  watchdog_interval: 60      # how often to send a watchdog
  watchdog_timeout: 120   # expect a watchdog within this duration
  acknowledgement_timeout: 20
  command_response_timeout: 20
  status_response_timeout: 20
  status_update_timeout: 20

connect_timeout: 60
disconnect_timeout: 60
ready_timeout: 60

command_timeout: 180
status_timeout: 180
status_update_rate: 1  # when subscribing to status messages, use rate of a message per 1 second
subscribe_timeout: 180
alarm_timeout: 180
shutdown_timeout: 180



## Configuting the equipment
Modify the configuration in the equipment, so that it connect to the validator. This typically includes setting an IP address and port. If the site and the validator is running in the same machine, the IP adress will typically be `localhost`. The port defaults to 12111, although you can use another port if you like, just be sure to configure the equipment and the validator to use the same port.


## Security Codes
Some tests require security codes to run. Place these in config/secrets.yaml, in this format:

```yaml
security_codes:
  1: '0000'
  2: '0000'
```

The file config/secrets.yaml is gitignored and should not be added to the repository.

