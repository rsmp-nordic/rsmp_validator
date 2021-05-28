# Running tests
## Organization
Tests are located in the spec/ folder. They are organized into subfolders and files, according to equipment types and functional areas.

```sh
% tree spec -d                          
spec
├── site
│   ├── core
│   └── tlc
├── supervisor
└── support
```

The folder spec/support includes [helper classes and utilities](implementation.md). 

The file `spec/spec_helper.rb` will be included automatically, and will in turn include the required helpers, including the rsmp gem and the TestSite helper class, so they are available in tests.

## Running Test
Note: Before running tests, be sure to set up your test [configuration](configuring.md).

The RSMP Validator is based on the RSpec testing tool, so you use the `rspec` command to run tests. You should be located in the root of the project folder when running test.

```sh
% bundle exec rspec spec/site
............

Finished in 1.28 seconds (files took 0.20949 seconds to load)
12 examples, 0 failures
```

## Filtering Tests
You can use rspec command line options to filter which tests to run. See https://rspec.info/ for more info.

If you want to store you selection for easy reuse, add them to a file name .rspec-local, in the root of the project folder. RSpec will automatically use the options. Example:

```sh
--pattern spec/site/*   # run tests in spec/site/
--exclude-pattern spec/site/unknown_status_spec.rb    # skip tests in this file
--tag ~script           # exclude tests tagged with :script
```

 .rspec-local is git ignored, and will therefore not be added to the repo. 

You can also keep diffferent configurations, and pick on when running tests, eg:

```sh
% bundle exec rspec --options rspec_basic_tests
```

### Running tests again a local Ruby TLC site
For trying out the specs, you can run a local Ruby TLC site. You can configure short reconnect and timrout intervals, which will make the test quick to run:

```sh
% cd rmsp
% bundle exec rsmp site --type tlc --json --config config/tlc.yaml
2020-01-01 23:38:48 UTC                           Starting site RN+SI0001
2020-01-01 23:38:48 UTC                           Connecting to superviser at 127.0.0.1:12111
2020-01-01 23:38:48 UTC                           No connection to supervisor at 127.0.0.1:12111
2020-01-01 23:38:48 UTC                           Will try to reconnect again every 0.1 seconds..
```

Once it's running, you can run the validator site specs, and you will see the Ruby TLC site respond to e.g. request to switch signal plan:

```sh
2020-01-01 23:38:54 UTC  6697976b5     -->  c776  Received CommandRequest {"mType":"rSMsg","type":"CommandRequest","ntsOId":"","xNId":"","cId":"TC","arg":[{"cCI":"M0002","cO":"setPlan","n":"status","v":"True"},{"cCI":"M0002","cO":"setPlan","n":"securityCode","v":"0000"},{"cCI":"M0002","cO":"setPlan","n":"timeplan","v":"2"}],"mId":"c77665c1-f7cc-4488-8bcb-f809939e0e20"}
2020-01-01 23:38:54 UTC                           Switching to plan 2
```

See the [rsmp gem](https://github.com/rsmp-nordic/rsmp) documentation for details on how to run Ruby sites and supervisors.
