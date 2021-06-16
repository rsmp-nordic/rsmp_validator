# About
rsmp-validator is a tool written in Ruby for testing RSMP equipment or software with RSpec.

It uses the rsmp gem to handle RSMP communication.

# Quick Start

```sh
% cat config/validator.yaml 
site: config/my_tlc.yaml   # config for eqiupment to be tested

% bundle exec rspec spec/site
Based on the input files, we are testing a site
Loading config from config/ci/my_tlc.yaml
Run options: exclude {:script=>true}
...............................................................................

Finished in 6.22 seconds (files took 0.60681 seconds to load)
79 examples, 0 failures
```

# Documentation
Please see the [guides](guides/introduction.md) for more information.

## Testing RSMP equipment
A local RSMP supervisor will be started on 127.0.0.1:12111. The site is expected to connect to it. You might have to adjust network settings to enable the site to reach the supervisor.

Once the site has connected, tests will be run to validate aspects like connection sequence, commmands, alarms, etc.

Some tests specify that the connection is reestablished before the test is run. This is useful when testing connection sequence, etc. Otherwise the connection will be kept open between tests, which will speed up execution.

To run test, cd to the root of this project, then:
	
```
% bundle exec rspec spec/site
............

Finished in 1.28 seconds (files took 0.20949 seconds to load)
12 examples, 0 failures
```

## Testing RSMP supervisor systems
The validator preliminary support for testing supervisor systems. See the [guides](guides/configuring.md) for more info.

## Choosing which tests to run
You can use rspec command line [options](https://rspec.info/) to filter which tests to run.

For example, you can run test only in specific files or folders, only run tests with (or without) certain tags, etc. 

If you want to store your selection for easy reuse, add them to a file name .rspec-local, in the root of the project folder. RSpec will automatically use the options. Example:

```
--pattern spec/site/*   # run tests in spec/site/
--exclude-pattern spec/site/unknown_status_spec.rb    # skip tests in this file
--tag ~script           # exclude tests tagged with :script
```

 .rspec-local is git ignored, and will therefore not be added to the repo. 

You can also keep diffferent configurations, and pick on when running tests, eg:

```
% bundle exec rspec --options rspec_basic_tests
```



