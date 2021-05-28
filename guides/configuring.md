# Configuring

To test a site, the validator needs some information about it. For example, the validator needs to know the SXL (type of equipment), what signal plans is has, etc. Before testing, you need to puts this information into a configuration file, in YAML format.

1. Setup a configuration file for the site.
2. Modify the site RSMP configuration, so that it connect to the validator

## Choosing the type of equipment you test
The validator requires knowledge about the equipment tested. This is stored in the config files in config/.
By default config/ruby.yaml is used. To use another config, copy config/validator_example.yaml into  config/validator.yaml, and edit it to point to the relevant config file. config/validator.yaml is gitignored.



## Security Codes
Some tests require security codes to run. Place these in config/secrets.yaml, in this format:

```yaml
security_codes:
  1: '0000'
  2: '0000'
```

The file config/secrets.yaml is gitignored and should not be added to the repository.

