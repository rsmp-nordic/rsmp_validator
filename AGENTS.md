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

You can run a RSMP site locally to interact with your test:
% bundle exec rsmp site --config config/simulator/tlc.yaml

This will keep running until you close it, so run it in a separate terminal.


Now you can rspec tests, which will communicate with the site your started, using RSMP:
% SITE_CONFIG=config/gem_tlc.yaml bundle exec rspec spec/site --format documentation

Use --format Validator::Details to see addional logging.


### Testing RSMP supervisors
Tests for sites are located in spec/supervisor/.
When testing a supervisor, the validator acts as a site and connects to the supervisor.

You can run a RSMP supervisor locally to interact with your test:
% bundle exec rsmp site --config config/simulator/supervisor.yaml

This will keep running until you close it, so run it in a separate terminal.


Now you can rspec tests, which will communicate with the site your started, using RSMP:
% SITE_CONFIG=config/gem_supwervisor.yaml bundle exec rspec spec/site --format documentation

Use --format Validator::Details to see addional logging.
