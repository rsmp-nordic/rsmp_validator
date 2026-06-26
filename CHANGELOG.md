# Changelog

## 0.1.0
- package the validator as the `rsmp-validator` gem with the `rsmp-validator` executable
- migrate the conformance test suite from RSpec to sus
- move reusable validator support code into `lib/rsmp/validator`
- ship conformance tests and simulator configs with the gem
- add support for RSMP Core 3.3.0
- update default examples and workflows to use the current `rsmp` gem and Core 3.3.0 configuration style
- replace the old RSpec/YARD documentation pipeline with the sus test documentation generator

## 0.1.1
- stop requiring bundler from the executable

## 0.2.0
- add cli options, replacing env variables, update workflows accordingly
- add config validation and compliance report output
- update simulator configs and workflows
- update rsmp gem, which include update schemas for all core/sxl versions

