---
layout: page
title: Testing
permalink: /testing/
parent: Getting Started
nav_order: 4
---

# Running tests
## Organization
Tests are located in the `spec/` folder. They are organized into sub-folders and files, according to system type, specification and functional areas.

```
% tree spec -d                          
spec
├── site          # tests for sites (equipment)
│   ├── core      # tests covering core specification
│   └── tlc       # tests for traffic light controllers
├── supervisor    # tests for supervisor systems (experimental)
└── support       # helper classes and other support files 
```

## Running Tests
Note: Before running tests, be sure to set up your test [configuration]({{ site.baseurl}}{% link pages/configuring.md %}).

The RSMP Validator is based on the RSpec testing tool, so you use the `rspec` command to run tests. You should be located in the root of the project folder when running test.

Test a site by running tests covering the core specification:

```
% bundle exec rspec spec/site/core
Using test config config/gem_tlc.yaml
Run options: exclude {:rsmp=>[unless relevant for 3.1.5]}
....

Finished in 1.01 seconds (files took 0.64491 seconds to load)
4 examples, 0 failures
```

In this example, the tests are running against a TLC emulator from the rsmp gem, running on the local machine, which is why the tests run in just about 1 second.


## Filtering Tests
You can use rspec command line [options](https://rspec.info/) to filter which tests to run.

If you want to store you selection for easy reuse, add them to a file name .rspec-local, in the root of the project folder. RSpec will automatically use the options. Example:

```
% cat .rspec-local
--pattern spec/site/*   # run tests in spec/site/
--exclude-pattern spec/site/unknown_status_spec.rb    # skip tests in this file
--tag ~programming           # exclude tests tagged with :programming
```

 .rspec-local is git ignored, and will therefore not be added to the repo. 

You can also keep different configurations, and pick one when running tests, e.g.:

```
% bundle exec rspec --options my_rspec_options
```

### Running tests against a local RSMP site

There are two ways to test against a local RSMP site:

#### Option 1: Auto Node Feature (For Development)

If you're developing the RSMP gem or validator itself, you can use the **auto node feature** to automatically start a local site to test. See the [Auto Node]({{ site.baseurl}}{% link pages/auto.md %}) page for details.

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

<<<<<<< HEAD
Once it's running, you can run the validator site specs in another terminal, and you will see the Ruby TLC site respond to e.g. request to switch signal plan:
=======
Once it's running, you can run the validator site specs, and you will see the Ruby TLC site respond to e.g. requests to switch signal plan:
>>>>>>> 035e48c (Fix typos, grammar, and improve clarity in main documentation files)

```
2020-01-01 23:38:54 UTC  6697976b5     -->  c776  Received CommandRequest {"mType":"rSMsg","type":"CommandRequest","ntsOId":"","xNId":"","cId":"TC","arg":[{"cCI":"M0002","cO":"setPlan","n":"status","v":"True"},{"cCI":"M0002","cO":"setPlan","n":"securityCode","v":"0000"},{"cCI":"M0002","cO":"setPlan","n":"timeplan","v":"2"}],"mId":"c77665c1-f7cc-4488-8bcb-f809939e0e20"}
2020-01-01 23:38:54 UTC                           Switching to plan 2
```

See the [rsmp gem](https://github.com/rsmp-nordic/rsmp) documentation for details on how to run Ruby sites and supervisors.

### Alarms and Programming
Testing alarms require some way to trigger them.

There's not yet any way to trigger alarms directly via RSMP. But often you can program the equipment to raise an alarm when a specific input is activated. If that's the case, use the `alarm_triggers` item in the validator config to specify which input activates which alarm:

```yaml
alarm_triggers:
  A0302: 
    input: 7
    component: DL1
```

Tests that rely on device programming are tagged with :programming. If the device cannot be programmed to raise alarm on input activation, you should skip tests that rely on this, by passing the `--tag ~programming` as an option to the `rspec` command:

```
% bundle exec rspec spec/site/ --tag ~programming
```
 
## RSpec Helpers and Options
The file `spec/spec_helper.rb` will be included automatically by RSpec, because the file `.rspec` has the following options:

```yaml
--require spec_helper
```
 
The file `spec/spec_helper.rb` will in turn include the required dependencies, including the rsmp gem and files in `spec/support/`, which define helper classes and methods.

## Git Ignores
The file .gitignore is set up to ignore files and folders that are typically used for private configurations, including `config/private/` and all secrets*.yaml files in `config/`.