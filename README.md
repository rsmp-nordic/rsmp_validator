# About
rsmp-validator is a tool written in Ruby for testing RSMP equipment or software with RSpec.

It uses the rsmp gem to handle RSMP communication.

## Installation
Make sure you have Ruby installed. Then ensure you have the 'bundler' gem installed.

Now run this to install gems:

```
% bundle
```

Some tests require security codes to run. Place these in config/secrets.yaml, in this format:

```yaml
security_codes:
  1: '0000'
  2: '0000'
```

The file config/secrets.yaml is gitignored and should not be added to the repository.

### Choosing the type of equipment you test
The validator requires knowledge about the equipment tested. This is stored in the config files in config/.
By default config/ruby.yaml is used. To use another config, copy config/validator_example.yaml into  config/validator.yaml, and edit it to point to the relevant config file. config/validator.yaml is gitignored.


## Testing an RSMP site
A local RSMP supervisor will be started on 127.0.0.1:12111. The site is expected to connect to it. You might have to adjust network settings to enable the site to reach the supervisor.

Once the site has connected, tests will be run to validate aspects like connection sequence, commmands, alarms, etc.

Some tests specify that the connection is reestablished before the test is run. This is useful when testing connection sequence, etc. Otherwise the connection will be kept open between tests, which will speed up execution.

To run test, cd to the root of this project, then:
	
~~~~
% rspec spec/site
............

Finished in 1.28 seconds (files took 0.20949 seconds to load)
12 examples, 0 failures
	
~~~~

See https://rspec.info/ for more info about how to run specific tests, formatting output, etc.

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
A local RSMP site will be started. The site will try to connect to the remote supervisor at   127.0.0.1:12111. You might have to adjust network settings to enable the site to reach the supervisor.

To run tests, cd to the root of this project, then:
	
~~~~
% rspec spec/supervisor
............

Finished in 1.28 seconds (files took 0.20949 seconds to load)
12 examples, 0 failures
	
~~~~


