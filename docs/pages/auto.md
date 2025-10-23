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

With the auto node feature, the validator start a local site which connect to the supervisor and is then tested. Similarly, when testing a supervisor, it will start a local supervisor which will be tested.

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
###  Environment Variables
You can also enable the auto node feature using environment variables.

Automatically start a site to be tested:

```shell
AUTO_SITE_CONFIG=config/simulator/tlc.yaml bundle exec rspec spec/site/core
```

Or automatically start a supervisor to be tested:

```shell
AUTO_SUPERVISOR_CONFIG=config/simulator/supervisor.yaml bundle exec rspec spec/supervisor
```


## Configurations
The auto node config file should contain the settings for the site or supervisor you want to start. See the `rsmp` gem for details.

You can use these as templates:
- `config/simulator/tlc.yaml`
- `config/simulator/supervisor.yaml`


