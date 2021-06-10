# How it Works

## Overview
A RSMP supervisor will be started by the validator and the site is expected to connect to it. 

Once the site has connected, tests will be run to validate aspects like connection sequence, commmands, alarms, etc.

To speed up testing, the connection will be kept open across tests when possible. However, tests specify whether the connection must be closedd and reestablished before the test is run. This is useful when testing connection sequence, etc.

## JSON Schema validation
All messages are checked against the RSMP JSON Schema to check that they have the correct format, attribute names, etc.

## Concurrency, Async and the TestSite helper
The validator uses the `rsmp` gem to handle RSMP communication. The gem uses the `async` library to handle concurrent connections.

This [TestSite](test_site.md) class handles running the RSMP supervisor that that site connects to, and provides a few methods that that can be used in tests to wait for the site to be connected (or disconnected).

The supervisor runs inside an Async event-reactor. The reactor must be stopped between test, to give RSpec an option to run and move on to the next test. The TestSite handles pausing and resuming the event reactor between tests.

## RSpec Helpers and Options
The file `spec/spec_helper.rb` will be included automatically by RSpec, because the file `.rspec` has the following options:

```yaml
--require spec_helper
```
 
The file `spec/spec_helper.rb`and will in turn include the required dependencies, including the rsmp gem and files in `spec/support/`, which defines helper classes and methods.

## Git Ignores
The file .gitignore is setup to ignore files and folders that typically use used for private configurations, including `config/private/` and all secrets*.yaml files in `config/`.
`