---
layout: page
title: Testing
permalink: /testing/
parent: Getting Started
nav_order: 4
---

# Running tests
## Organization
Tests are located in the `test/` folder. They are organized into sub-folders and files, according to system type, specification and functional areas.

```
% tree test -d
test
├── site          # tests for sites (equipment)
│   ├── core      # tests covering core specification
│   └── tlc       # tests for traffic light controllers
└── supervisor    # tests for supervisor systems (experimental)
```

## Running Tests
Note: Before running tests, be sure to set up your test [configuration]({{ site.baseurl}}{% link pages/configuring.md %}).

The RSMP Validator uses the [sus](https://github.com/socketry/sus) testing framework. Use the `rsmp-validator run` command to run conformance tests. You should be located in the root of the project folder when running tests.

Test a site by running tests covering the core specification, using the auto node feature to start a local TLC site automatically:

```
% SITE_CONFIG=config/gem_tlc.yaml AUTO_SITE_CONFIG=config/simulator/tlc.yaml bundle exec rsmp-validator run test/site/core
```

To run all site tests:

```
% SITE_CONFIG=config/gem_tlc.yaml AUTO_SITE_CONFIG=config/simulator/tlc.yaml bundle exec rsmp-validator run test/site
```

See the [Auto Node]({{ site.baseurl}}{% link pages/auto.md %}) page for details on the auto node feature.

## Filtering Tests
You can pass one or more paths to the `rsmp-validator run` command to select which tests to run:

```
% SITE_CONFIG=config/gem_tlc.yaml AUTO_SITE_CONFIG=config/simulator/tlc.yaml bundle exec rsmp-validator run test/site/core test/site/tlc/clock_spec.rb
```

You can override the configured Core and SXL versions for a run without editing the YAML config:

```console
% SITE_CONFIG=config/gem_tlc.yaml bundle exec rsmp-validator run test/site --core 3.3.0 --sxls tlc:1.3.0
```

Use a comma-separated `name:version` list to test with several SXLs:

```console
% SITE_CONFIG=config/gem_tlc.yaml bundle exec rsmp-validator run test/site --sxls tlc:1.3.0,vms:1.0.0
```

### Running tests against a local RSMP site

There are two ways to test against a local RSMP site:

#### Option 1: Auto Node Feature (Recommended for Development)

Use the **auto node feature** to automatically start a local site to test. See the [Auto Node]({{ site.baseurl}}{% link pages/auto.md %}) page for details.

#### Option 2: Manual RSMP Site (For Testing Real Equipment)

Alternatively, you can manually start a local Ruby TLC site using the `rsmp` command from the rsmp gem.

Because the validator by default listens on port 13111, you should tell the site to connect on this port. You can do this either by editing the configuration, or using the `supervisor` command line option, as shown below.

You can use short reconnect and timeout intervals in the config file, which will make the tests quick to run.

```
% cd rsmp
% bundle exec rsmp site --type tlc --json --config config/tlc.yaml --supervisors localhost:13111
2020-01-01 23:38:48 UTC                           Starting site RN+SI0001
2020-01-01 23:38:48 UTC                           Connecting to supervisor at 127.0.0.1:13111
2020-01-01 23:38:48 UTC                           No connection to supervisor at 127.0.0.1:13111
2020-01-01 23:38:48 UTC                           Will try to reconnect again every 0.1 seconds..
```

Once it's running, you can run the validator site tests and you will see the Ruby TLC site respond to requests, e.g. requests to switch signal plan:

```
2020-01-01 23:38:54 UTC  6697976b5     -->  c776  Received CommandRequest {"mType":"rSMsg","type":"CommandRequest","ntsOId":"","xNId":"","cId":"TC","arg":[{"cCI":"M0002","cO":"setPlan","n":"status","v":"True"},{"cCI":"M0002","cO":"setPlan","n":"securityCode","v":"0000"},{"cCI":"M0002","cO":"setPlan","n":"timeplan","v":"2"}],"mId":"c77665c1-f7cc-4488-8bcb-f809939e0e20"}
2020-01-01 23:38:54 UTC                           Switching to plan 2
```

See the [rsmp gem](https://github.com/rsmp-nordic/rsmp) documentation for details on how to run Ruby sites and supervisors.

### Alarms and Programming
Testing alarms requires some way to trigger them.

There's not yet any way to trigger alarms directly via RSMP. But often you can program the equipment to raise an alarm when a specific input is activated. If that's the case, use the `alarm_triggers` item in the validator config to specify which input activates which alarm:

```yaml
alarm_triggers:
  A0302: 
    input: 7
    component: DL1
```

Tests that rely on device programming are tagged with `:programming`. You can skip them by passing the relevant test paths explicitly and excluding files you don't need.

## Git Ignores
The file `.gitignore` is set up to ignore files and folders that are typically used for private configurations, including `config/private/` and all `secrets*.yaml` files in `config/`.
