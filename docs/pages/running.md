---
layout: page
title: Testing
permalink: /testing/
parent: Getting Started
nav_order: 3
---

# Running tests
## Organization
Tests are located in the `spec/` folder. They are organized into subfolders and files, according to system type, specification and functional areas.

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
Note: Before running tests, be sure to set up your test [configuration]({% link pages/configuring.md %}).

The RSMP Validator is based on the RSpec testing tool, so you use the `rspec` command to run tests. You should be located in the root of the project folder when running test.

Test a site, by running tests covering the core specification:

```
% bundle exec rspec spec/site/core
Using test config config/gem_tlc.yaml
Run options: exclude {:rsmp=>[unless relevant for 3.1.5], :script=>true}
....

Finished in 1.01 seconds (files took 0.64491 seconds to load)
4 examples, 0 failures
```

In this exampple, the tests are running against a TLC emulator from the rsmp gem, running on the local machine, which is why the tests run in just about 1 second.


## Filtering Tests
You can use rspec command line [options](https://rspec.info/) to filter which tests to run.

If you want to store you selection for easy reuse, add them to a file name .rspec-local, in the root of the project folder. RSpec will automatically use the options. Example:

```
% cat .rspec-local
--pattern spec/site/*   # run tests in spec/site/
--exclude-pattern spec/site/unknown_status_spec.rb    # skip tests in this file
--tag ~script           # exclude tests tagged with :script
```

 .rspec-local is git ignored, and will therefore not be added to the repo. 

You can also keep diffferent configurations, and pick on when running tests, eg:

```
% bundle exec rspec --options my_rspec_options
```

### Running tests again a local Ruby TLC site
For trying out the specs, you can juse the `rsmp` command from the resmp gem to run a local Ruby TLC site. 

Because the validator by default listens on port 13111, use should tell the site to connect on this port. You can do this either by editing the configuration, or using the `supervisor` command line option, as shown below.

You can use short reconnect and timeout intervals in the config file, which will make the test quick to run.

```
% cd rmsp
% bundle exec rsmp site --type tlc --json --config config/tlc.yaml --supervisors localhost:13111
2020-01-01 23:38:48 UTC                           Starting site RN+SI0001
2020-01-01 23:38:48 UTC                           Connecting to superviser at 127.0.0.1:12111
2020-01-01 23:38:48 UTC                           No connection to supervisor at 127.0.0.1:12111
2020-01-01 23:38:48 UTC                           Will try to reconnect again every 0.1 seconds..
```

Once it's running, you can run the validator site specs, and you will see the Ruby TLC site respond to e.g. request to switch signal plan:

```
2020-01-01 23:38:54 UTC  6697976b5     -->  c776  Received CommandRequest {"mType":"rSMsg","type":"CommandRequest","ntsOId":"","xNId":"","cId":"TC","arg":[{"cCI":"M0002","cO":"setPlan","n":"status","v":"True"},{"cCI":"M0002","cO":"setPlan","n":"securityCode","v":"0000"},{"cCI":"M0002","cO":"setPlan","n":"timeplan","v":"2"}],"mId":"c77665c1-f7cc-4488-8bcb-f809939e0e20"}
2020-01-01 23:38:54 UTC                           Switching to plan 2
```

See the [rsmp gem](https://github.com/rsmp-nordic/rsmp) documentation for details on how to run Ruby sites and supervisors.

### Alarms and Scripts
Testing alarms require some way to trigger them.

There's not yet any way to trigger alarms via RSMP, so some other way is required. Some equipment provide other interfaces that makes it possible to trigger alarms.

If you can provide a script that can trigger the relevant alarms in the equipment, you can use this in tests. Such scripts are configured by adding `scripts` item in the validator config:

```yaml
scripts:
  activate_alarm: '/some/path/activate_alarm.sh'
  deactivate_alarm: '/some/path/deactivate_alarm.sh'
```

Otherwise you should probably skip the test by passing the `--tag ~script` as an option to the `rspec` command:

```
% bundle exec rspec spec/site/ --tag ~script
```
 
## RSpec Helpers and Options
The file `spec/spec_helper.rb` will be included automatically by RSpec, because the file `.rspec` has the following options:

```yaml
--require spec_helper
```
 
The file `spec/spec_helper.rb`and will in turn include the required dependencies, including the rsmp gem and files in `spec/support/`, which defines helper classes and methods.

## Git Ignores
The file .gitignore is setup to ignore files and folders that typically use used for private configurations, including `config/private/` and all secrets*.yaml files in `config/`.