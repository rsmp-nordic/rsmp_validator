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

#### Option 1: Using an external site process (for testing real equipment)
You can run a RSMP site locally to interact with your test:
% bundle exec rsmp site --config config/simulator/tlc.yaml

This will keep running until you close it, so run it in a separate terminal.

Now you can rspec tests, which will communicate with the site you started, using RSMP:
% SITE_CONFIG=config/gem_tlc.yaml bundle exec rspec spec/site --format documentation

#### Option 2: Using a programmatic site (for development)
For development on the rsmp gem, you can start a site programmatically within the validator, avoiding the need for a separate process.

Using environment variables:
% SITE_TO_TEST=config/simulator/tlc.yaml SITE_CONFIG=config/gem_tlc.yaml bundle exec rspec spec/site

Or configure it in config/validator.yaml:
```yaml
site: config/gem_tlc.yaml
site_to_test: config/simulator/tlc.yaml
```

Then simply run:
% bundle exec rspec spec/site --format documentation

Use --format Validator::Details to see additional logging.


### Testing RSMP supervisors
Tests for supervisors are located in spec/supervisor/.
When testing a supervisor, the validator acts as a site and connects to the supervisor.

#### Option 1: Using an external supervisor process (for testing real equipment)
You can run a RSMP supervisor locally to interact with your test:
% bundle exec rsmp supervisor --config config/simulator/supervisor.yaml

This will keep running until you close it, so run it in a separate terminal.

Now you can run rspec tests, which will communicate with the supervisor you started, using RSMP:
% SUPERVISOR_CONFIG=config/gem_supervisor.yaml bundle exec rspec spec/supervisor --format documentation

#### Option 2: Using a programmatic supervisor (for development)
For development on the rsmp gem, you can start a supervisor programmatically within the validator, avoiding the need for a separate process.

Using environment variables:
% SUPERVISOR_TO_TEST=config/simulator/supervisor.yaml SUPERVISOR_CONFIG=config/gem_supervisor.yaml bundle exec rspec spec/supervisor

Or configure it in config/validator.yaml:
```yaml
supervisor: config/gem_supervisor.yaml
supervisor_to_test: config/simulator/supervisor.yaml
```

Then simply run:
% bundle exec rspec spec/supervisor --format documentation

Use --format Validator::Details to see additional logging.
