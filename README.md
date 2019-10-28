# About
rsmp-validator is a tool written in Ruby for testing RSMP equipment or software with RSpec.

It uses the rsmp gem to handle RSMP communication.

## Installation
Make sure you have a Ruby installed. A version manager like rbenv is recommended.
Then ensure you have the 'bundler' gem installed.

The rsmp gem is not yet public, and is therefore currently loaded from a local file path.

First ensure you have a local checkout of the rsmp gem repository, and then adjust the path to the repo in the Gemfile to point to your local folder.
Note that the gem repo currently uses a git submodule to get the json schema. Read the readme in the gem repo to see how to setup the submodule.

Now run this to install gems:

```
% bundle
```

## Testing an RSPM site
A local RSMP supervisor will be started on 127.0.0.1:12111. The site is expected to connect to it. You might have to adjust network settings to enable the site to reach the supervisor.

Once the site has connected, tests will be run to validate aspects like connection sequence, commmands, alarms, etc.

Some tests specify that the connection is reestablished before the test is run. This is useful when testing connection sequence, etc. Otherwise the connection will be kept open between tests, which will speed up execution.

To run test, cd to the root of this project, then:
	
~~~~
% rspec test/site
............

Finished in 1.28 seconds (files took 0.20949 seconds to load)
12 examples, 0 failures
	
~~~~

See https://rspec.info/ for more info about how to run specific tests, formatting output, etc.

## Testing an RSMP supervisor
To be implemented.
