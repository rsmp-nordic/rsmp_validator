# AGENTS.md file

## About
This repo contains the RSMP Validator, which is used to verify RSMP (Road Side Message Protocol) implementations.

It's written in Ruby and uses the RSpec test framework.

## How it works
RSMP communication is handled by the 'rsmp' gem.
Validation of RSMP messages is handled by the 'rsmp_schema' gem.

The 'async' gem is used to handle concurrency. All tests run in an Async Reactor. The reactor is paused at the end of each test, then continued at the start of the next test. This is done to be able to keep
the TCP connection open between test, which significantly speeds up testing.

You can test either RSMP sites or supervisor.

## Auto Node Logging
When using the auto node feature to start a local site or supervisor for testing, each auto node creates its own logger instance. By default, output is interleaved with the validator output and formatted consistently. You can use the `prefix` option in the auto node config to distinguish the sources, or use the `path` option to direct output to a separate file.

## Files
- config/ contains test configurations.
- docs/ contains documentation, as a Jekyll site published using Github Pages.
- yard/ contains YARD code for extracting documentation from RSpec test code.
- spec/ contains all test files.
- spec/support/ contains support files, e.g. for running tests in an Async reactor.
- spec/site/ contains test for RSMP sites.
- spec/supervisor/ contains tests for RSMP supervisors.


## Development Guidelines
This repo a custom Github Actions workflow which should already have set up Ruby, bundler and gems. DO NOT install them manually.

Always run gem executable with 'bundle exec', to ensure the correct gem environment.

## Testing instructions
When running tests, the validator will determine wether you're testing a site or a supervisor based on whether test files are located in spec/site/ or spec/supervisor.

### Testing RSMP sites
Tests for sites are located in spec/site/.
When testing a site, the validator acts as a supervisor and waits for the site to connect.

The easiest way to run tests locally is to use the **auto node feature**, which automatically starts a local site to be tested:

% AUTO_SITE_CONFIG=config/simulator/tlc.yaml bundle exec rspec spec/site --format documentation

This will automatically start a local RSMP site, run the tests against it, and stop the site when done.

Use --format Validator::Details to see additional logging.

#### Alternative: Manual Background Process
Alternatively, you can manually start a RSMP site in a separate terminal:
% bundle exec rsmp site --config config/simulator/tlc.yaml

Then run tests in another terminal:
% SITE_CONFIG=config/gem_tlc.yaml bundle exec rspec spec/site --format documentation

### Testing RSMP supervisors
Tests for supervisors are located in spec/supervisor/.
When testing a supervisor, the validator acts as a site and connects to the supervisor.

The easiest way to run tests locally is to use the **auto node feature**, which automatically starts a local supervisor to be tested:

% AUTO_SUPERVISOR_CONFIG=config/simulator/supervisor.yaml bundle exec rspec spec/supervisor --format documentation

This will automatically start a local RSMP supervisor, run the tests against it, and stop the supervisor when done.

Use --format Validator::Details to see additional logging.

#### Alternative: Manual Background Process
Alternatively, you can manually start a RSMP supervisor in a separate terminal:
% bundle exec rsmp supervisor --config config/simulator/supervisor.yaml

Then run tests in another terminal:
% SITE_CONFIG=config/gem_supervisor.yaml bundle exec rspec spec/supervisor --format documentation

## Code Quality
Before submitting changes, you must run rubocop to check for code style violations and fix any issues:

% bundle exec rubocop

To automatically fix violations where possible:
% bundle exec rubocop -a
