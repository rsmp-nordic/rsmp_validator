---
layout: page
title: Auto Node
permalink: /auto/
parent: Getting Started
nav_order: 5
---

# Auto Node Feature
The auto node feature allows you to programmatically start a local site or supervisor to be tested, instead of connecting to an external one. 

This is an advanced feature primarily useful for:
- Developing or debugging the RSMP gem itself
- Developing or testing the validator test suite

For testing real equipment or production systems, you should connect to external equipment as described in the [Testing]({{ site.baseurl}}{% link pages/running.md %}) documentation.

## How It Works
Usually, when testing a site, the validator starts a supervisor and waits for the external site to connect.

With the auto node feature, the validator starts a local site that connects to the supervisor and is then tested. Similarly, when testing a supervisor, it starts a local supervisor that is tested.

The auto site/supervisor runs inside the same Async reactor as the validator.

## Configuration
There are two ways to enable the auto node feature.
Environment variables take precedence over the `config/validator.yaml` file settings.

### config/validator.yaml
Add either `auto_site` or `auto_supervisor` to your `config/validator.yaml` file:

```yaml
# ...
# automatically start a site to be tested
auto_site: config/simulator/tlc.yaml
```

Or:
```yaml
# ...
# automatically start a supervisor to be tested
auto_supervisor: config/simulator/supervisor.yaml
```
### Environment Variables
You can also enable the auto node feature using environment variables.

Automatically start a site to be tested:

```shell
SITE_CONFIG=config/gem_tlc.yaml AUTO_SITE_CONFIG=config/simulator/tlc.yaml bundle exec rsmp-validator run test/site/core
```

Or automatically start a supervisor to be tested:

```shell
SUPERVISOR_CONFIG=config/gem_supervisor.yaml AUTO_SUPERVISOR_CONFIG=config/simulator/supervisor.yaml bundle exec rsmp-validator run test/supervisor
```


## Configurations
The auto node config file should contain the settings for the site or supervisor you want to start. See the `rsmp` gem for details.

You can use these as templates:
- `config/simulator/tlc.yaml`
- `config/simulator/supervisor.yaml`

## Logging
Auto nodes create their own logger instance, which allows you to control their output independently from the validator and local node loggers.

### Interleaved Output (Default)
By default, output from the auto node is interleaved with the validator's output. To distinguish between the validator and auto node output, you can use the `prefix` option in the auto node's log configuration:

```yaml
# config/simulator/tlc.yaml
log:
  prefix: '[TLC]       '  # Prefix to identify auto site output
  json: true
  acknowledgements: false
  watchdogs: false
```

Enable RSMP logging with the `--log` flag:

```shell
bundle exec rsmp-validator run test/site --log
```

Or write RSMP logs to a file:

```shell
bundle exec rsmp-validator run test/site --log-path logs/details.log
```

### Separate Log File
Alternatively, you can direct the auto node's output to a separate file using the `path` option:

```yaml
# config/simulator/tlc.yaml
log:
  path: 'logs/auto_site.log'  # Direct output to separate file
  debug: true
  json: true
```

With this configuration:
- **Auto node logs** are written directly to `logs/auto_site.log` 
- **Validator logs** continue through the validator log stream controlled by `--log` or `--log-path`
- The two output streams are **completely independent**

This means the auto node's logs are written to the configured file independently from sus output.

### Log Configuration Options
The auto node's `log` section accepts all the same options as the RSMP logger. See the [rsmp gem documentation](https://github.com/rsmp-nordic/rsmp) for complete details. Common options include:

- `path`: File path for log output
- `prefix`: Text to prepend to each log line
- `debug`: Enable debug messages
- `json`: Include JSON representation of messages
- `acknowledgements`: Show acknowledgement messages
- `watchdogs`: Show watchdog messages
- `timestamp`: Show timestamps
- `component`: Show component information
