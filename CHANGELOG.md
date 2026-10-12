# Changelog

## unreleased
- remove obsolete generated documentation pages during deployment to prevent duplicate index entries

## 0.3.3
- update subscription test to ensure we actually receive periodid updates
- add operational equipment safety note to the documentation

## 0.3.2
- include the example validator configuration and test fixtures in Docker images
- add a Docker smoke-test workflow that runs a connection test
- update Docker documentation
- add a safety note about testing operational equipment to the README

## 0.3.1
- use canonical three-component RSMP Core and SXL versions internally
- preserve legacy two-component Core and SXL strings when configuring local test nodes
- update the rsmp gem

## 0.3.0
- adapt validator helpers and conformance tests to the rsmp gem's new result model
- abort the current test after operation failures or unexpected exceptions
- fix Core 3.2.0 connection-sequence tests advertising the noncanonical version 3.2
- skip log uploads and compliance-result updates when Ruby setup fails in workflows
- update the rsmp gem

## 0.2.2
- exit with a failure status without showing a backtrace for connection errors

## 0.2.1
- ensure traffic light mode tests reset the controller to normal control
- use decoded boolean and integer values in emergency route tests
- update dependencies

## 0.2.0
- add cli options, replacing env variables, update workflows accordingly
- add config validation and compliance report output
- update simulator configs and workflows
- update rsmp gem, which includes updated schemas for all core/sxl versions

## 0.1.1
- stop requiring bundler from the executable

## 0.1.0
- package the validator as the `rsmp-validator` gem with the `rsmp-validator` executable
- migrate the conformance test suite from RSpec to sus
- move reusable validator support code into `lib/rsmp/validator`
- ship conformance tests and simulator configs with the gem
- add support for RSMP Core 3.3.0
- update default examples and workflows to use the current `rsmp` gem and Core 3.3.0 configuration style
- replace the old RSpec/YARD documentation pipeline with the sus test documentation generator
