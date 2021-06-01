# How it Works

## Flow
A local RSMP supervisor will be started on 127.0.0.1:12111. The site is expected to connect to it. 

Once the site has connected, tests will be run to validate aspects like connection sequence, commmands, alarms, etc.

Some tests specify that the connection is reestablished before the test is run. This is useful when testing connection sequence, etc. Otherwise the connection will be kept open between tests, which will speed up execution.

## JSON Schema validation
All messages are checked against the RSMP JSON Schema to check that they have the correct format, attribute names, etc.

## Helpers
More about:
TestSite
async
etc


## RSpec Helpers and Options
The file `spec/spec_helper.rb` will be included automatically by RSpec, because the file `.rspec` has the following options:

```yaml
--require spec_helper
```
 
The file `spec/spec_helper.rb`and will in turn include the required dependencies, including the rsmp gem and files in `spec/support/`, which defines helper classes and methods.

## Git Ignores
The file .gitignore is setup to ignore files and folders that typically use used for private configurations, including `config/private/` and all secrets*.yaml files in `config/`.
`