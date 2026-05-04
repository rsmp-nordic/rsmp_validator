# AGENTS.md file

## About
This repo contains the RSMP Validator, which is used to verify RSMP (Road Side Message Protocol) implementations.

It's written in Ruby and uses the Sus test framework.

## How it works
Tests are written using the sus test framework.

RSMP communication is handled by the 'rsmp' gem.
Validation of RSMP messages is handled by the 'rsmp_schema' gem.

The 'async' gem is used to handle concurrency. All tests run in an Async Reactor.
The TCP connection is usually kept open between test, to speeds up testing, but tests can specifify
that they need to run freshly connected, or disconnected.

You can test either RSMP sites or supervisor.

## Auto Node Logging
When using the auto node feature to start a local site or supervisor for testing, each auto node creates its own logger instance. By default, output is interleaved with the validator output and formatted consistently. You can use the `prefix` option in the auto node config to distinguish the sources, or use the `path` option to direct output to a separate file.

## Files
- config/ contains test configurations.
- docs/ contains documentation, as a Jekyll site published using Github Pages.
- test/ contains all test files.
- test/support/ contains support files, e.g. for running tests in an Async reactor.
- test/site/ contains test for RSMP sites.
- test/supervisor/ contains tests for RSMP supervisors.


## Development Guidelines
This repo a custom Github Actions workflow which should already have set up Ruby, bundler and gems. DO NOT install them manually.

Always run gem executable with 'bundle exec', to ensure the correct gem environment.

## Testing instructions
When running tests, the validator will determine wether you're testing a site or a supervisor based on whether test files are located in test/site/ or test/supervisor.

### Testing RSMP sites
Tests for sites are located in test/site/.
When testing a site, the validator acts as a supervisor and waits for the site to connect.

The easiest way to run tests locally is to use the **auto node feature**, which automatically starts a local site to be tested:

% bundle exec exe/rsmp_validator test/site

This will automatically start a local RSMP site, run the tests against it, and stop the site when done.

use --verbose to see each tests and assertion and --log to see RSMP message logs.

#### Alternative: Manual Background Process
Alternatively, you can manually start a RSMP site in a separate terminal:
% bundle exec rsmp site --config config/simulator/tlc.yaml

Then run tests in another terminal:
% bundle exec exe/rsmp_validator test/site

### Testing RSMP supervisors
Tests for supervisors are located in test/supervisor/.
When testing a supervisor, the validator acts as a site and connects to the supervisor.

The easiest way to run tests locally is to use the **auto node feature**, which automatically starts a local supervisor to be tested:

% bundle exec exe/rsmp_validator test/supervisor

This will automatically start a local RSMP supervisor, run the tests against it, and stop the supervisor when done.

#### Alternative: Manual Background Process
Alternatively, you can manually start a RSMP supervisor in a separate terminal:
% bundle exec rsmp supervisor --config config/simulator/supervisor.yaml

Then run tests in another terminal:
% bundle exec exe/rsmp_validator test/supervisor

## Code Quality
Before submitting changes, you must run rubocop to check for code style violations and fix any issues:

% bundle exec rubocop

To automatically fix violations where possible:
% bundle exec rubocop -a
