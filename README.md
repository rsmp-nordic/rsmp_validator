# About
rsmp-validator is a tool written in Ruby for testing RSMP equipment or software with RSpec.

It uses the rsmp gem to handle RSMP communication.

# Quick Start

```sh
% cat config/validator.yaml 
rsmp_config_path: config/my_tlc.yaml   # config for eqiupment to be tested

% bundle exec rspec spec/site/core spec/site/tlc
Using test config config/ci/rsmp_gem.yaml
Warning: Config 'scripts' is missing from config/ci/rsmp_gem.yaml
Run options: exclude {:rsmp=>[unless relevant for 3.1.5], :script=>true}
...............................................................................

Finished in 6.22 seconds (files took 0.60681 seconds to load)
79 examples, 0 failures
```

# Documentation
Please see the [guides](guides/introction.md) for more information.

## Testing an RSMP site
A local RSMP supervisor will be started on 127.0.0.1:12111. The site is expected to connect to it. You might have to adjust network settings to enable the site to reach the supervisor.

Once the site has connected, tests will be run to validate aspects like connection sequence, commmands, alarms, etc.

Some tests specify that the connection is reestablished before the test is run. This is useful when testing connection sequence, etc. Otherwise the connection will be kept open between tests, which will speed up execution.

To run test, cd to the root of this project, then:
	
```
% rspec spec/site
............

Finished in 1.28 seconds (files took 0.20949 seconds to load)
12 examples, 0 failures
```

## Choosing which tests to run
You can use rspec command line options to filter which tests to run. See https://rspec.info/ for more info.

If you want to store you selection for easy reuse, add them to a file name .rspec-local, in the root of the project folder. RSpec will automatically use the options. Example:

```
--pattern spec/site/*   # run tests in spec/site/
--exclude-pattern spec/site/unknown_status_spec.rb    # skip tests in this file
--tag ~script           # exclude tests tagged with :script
```

 .rspec-local is git ignored, and will therefore not be added to the repo. 

You can also keep diffferent configurations, and pick on when running tests, eg:

```
% rspec --options rspec_basic_tests
```

### Running tests again a local Ruby TLC site
For trying out the specs, you can run a local Ruby TLC site. You can configure short reconnect and timrout intervals, which will make the test quick to run:

```
% cd rmsp
% cat config/tlc.yaml
supervisors:
  - ip: 127.0.0.1
    port: 12111

components:
  TC:
    type: main
    cycle_time: 10

watchdog_interval: 1
watchdog_timeout: 2
acknowledgement_timeout: 1
command_response_timeout: 1
status_response_timeout: 1
status_update_timeout: 1
reconnect_interval: 0.1

log:
  active: true

% bundle exec rsmp site --type tlc --json --config config/tlc.yaml
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

See the rsmp gem documentation for details on how to run Ruby sites.

## Testing an RSMP supervisor
Note: Testing supervisors is still experimental.

A local RSMP site will be started. The site will try to connect to the remote supervisor at 127.0.0.1:12111. You might have to adjust network settings to enable the site to reach the supervisor.

To run tests, cd to the root of this project, then:
	
```
% rspec spec/supervisor
............

Finished in 1.28 seconds (files took 0.20949 seconds to load)
12 examples, 0 failures
```


