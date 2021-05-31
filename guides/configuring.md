# Configuring
Before you run test, you should setup a configuration for the equipment you want to tests. 

For example, the validator needs to know the SXL (type of equipment), because the SXL is not send by the equipment when connecting.

Configurations are stored as YAML files in `config/`.

## Choosing a config file
By default the config `config/rsmp_gem.yaml` is used. That config is suited for running tests against a [Ruby TLC emulator](https://github.com/rsmp-nordic/rsmp)) running on your local machine.

To use another config, copy `config/validator_example.yaml` into  `config/validator.yaml`, and edit it to point to the relevant config file, eg:

```yaml
rsmp_config_path: config/ci/my_equipment.yaml
```

Note: The file `config/validator.yaml` is gitignored.


## Content of config files


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

