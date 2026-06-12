# RSMP Validator Agent Guide

This repository contains the RSMP Validator, a Ruby gem for testing RSMP site and supervisor implementations. It uses `sus` for tests, `async` for concurrency, and the `rsmp` gem for RSMP communication and JSON Schema validation.

## Where Things Live

- `lib/` contains reusable validator and documentation-generation code.
- `test/validator/` contains internal unit and integration tests that do not require an RSMP peer.
- `test/site/` contains conformance tests for RSMP sites. The validator acts as a supervisor and waits for the site to connect.
- `test/supervisor/` contains conformance tests for RSMP supervisors. The validator acts as a site and connects to the supervisor.
- `config/` contains validator and simulator configurations.
- `docs/` contains the Jekyll documentation site.

## Commands

- `bundle exec sus test/validator` runs the internal validator tests.
- `bundle exec rsmp-validator test/site` runs site conformance tests, usually with an auto-started local site.
- `bundle exec rsmp-validator test/supervisor` runs supervisor conformance tests, usually with an auto-started local supervisor.
- `bundle exec rubocop` checks Ruby style.
- `bundle exec rake spec_docs` regenerates test documentation under `docs/tests/`.

Always run gem executables through `bundle exec` so the correct bundle is used.

## Conformance Notes

- Test direction is inferred from the path: `test/site/` tests sites, and `test/supervisor/` tests supervisors.
- Conformance tests run inside an Async reactor.
- The TCP connection is usually reused between tests. Individual tests may require a fresh connection or a disconnected state.
- Auto node logging can be distinguished with the `prefix` option or written to a separate file with the `path` option.

## Editing Guidance

- Follow existing Ruby, `sus`, and Async patterns.
- Keep test changes clear about whether they target internal validator behavior or external RSMP conformance behavior.
- When changing generated documentation, update the source or generator first unless the task is specifically about generated output.
- Do not install Ruby, Bundler, or gems manually in CI-oriented environments; use the existing bundle setup.

## Validation

- Run the narrowest relevant test command after edits.
- Run `bundle exec rubocop` for Ruby changes when practical.
- If dependencies or an RSMP peer are unavailable, mention which validation was skipped and why.
