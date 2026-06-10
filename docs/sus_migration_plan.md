# Plan: Package rsmp_validator as gem with sus

## TL;DR
Convert rsmp_validator from an RSpec-based repo checkout into a distributable gem (`rsmp_validator`) that uses the `sus` test framework. Test files ship inside the gem; users run `rsmp_validator` to execute conformance tests against their RSMP site or supervisor. This eliminates the fiber-local data hack required by RSpec's incompatibility with Async.

Work is done in the existing `rsmp_validator` repo on the `sus` branch.

## Phase 1: Gemspec and project scaffold

1. Create `rsmp_validator.gemspec` including `lib/`, `test/`, `config/simulator/`, and `schemas/` in `spec.files`
2. Create `gems.rb` (sus style) replacing `Gemfile`
3. Set runtime dependencies: `rsmp`, `sus`, `sus-fixtures-async`, `activesupport`, `colorize`
4. Create `exe/rsmp_validator` executable that:
   - Accepts arguments: test path filter, `--config`, `--auto-site-config`, `--auto-supervisor-config`, `--verbose`
   - Determines mode (site/supervisor) from test path
   - Loads validator config
   - Sets up custom `Sus::Config` subclass
   - Loads the gem's bundled test files and runs them through sus

## Phase 2: Move support code into lib/

Move `spec/support/` → `lib/rsmp/validator/` (proper library code, not test support):

5. `lib/rsmp/validator.rb` — main module (replaces `spec/support/validator.rb`), stripped of all RSpec references
6. `lib/rsmp/validator/configuration.rb` — from `spec/support/validator/configuration.rb`, unchanged logic
7. `lib/rsmp/validator/tester.rb` — from `spec/support/tester.rb`, replace `include RSpec::Matchers` with sus assertions passed to methods
8. `lib/rsmp/validator/site_tester.rb` — from `spec/support/site_tester.rb`
9. `lib/rsmp/validator/supervisor_tester.rb` — from `spec/support/supervisor_tester.rb`
10. `lib/rsmp/validator/auto_node.rb` — from `spec/support/auto_node.rb`
11. `lib/rsmp/validator/auto_site.rb` — from `spec/support/auto_site.rb`
12. `lib/rsmp/validator/auto_supervisor.rb` — from `spec/support/auto_supervisor.rb`
13. `lib/rsmp/validator/config_normalizer.rb` — from `spec/support/config_normalizer.rb`, unchanged
14. `lib/rsmp/validator/log.rb` — from `spec/support/log_helpers.rb`
15. `lib/rsmp/validator/options/site_test_options.rb` — unchanged
16. `lib/rsmp/validator/options/supervisor_test_options.rb` — unchanged

Delete `spec/support/described_types.rb` entirely — it exists only to satisfy RuboCop RSpec cops.

## Phase 3: Formatters → sus output

17. Replace 4 RSpec formatters with sus output integration:
    - `ReportStream` becomes a simple sus output wrapper — RSMP::Logger writes to sus output
    - `Brief` formatter → default sus output (sus already provides brief pass/fail)
    - `Details` formatter → sus verbose mode (`--verbose`)
    - `Steps` formatter → custom sus output class if needed
    - `List` formatter → likely unnecessary, sus has built-in listing
    - All formatters drop `RSpec::Core::Formatters` dependency, use `Sus::Output` / colorize directly

## Phase 4: Convert test files from RSpec to sus

18. Rename `spec/` → `test/` (sus convention)
19. `test/site/` and `test/supervisor/` directory structure stays the same
20. Convert each `_spec.rb` to sus syntax:
    - `RSpec.describe Foo do` → `describe "Foo" do`
    - `specify 'name', sxl: '>=1.0.7' do` → `it 'name' do` with `skip "requires sxl >= 1.0.7" unless Validator.sxl_matches?(">= 1.0.7")` inside
    - `include Validator::Helpers::Status` → same (sus supports module include in describe blocks)
    - `expect(...).to` → same (sus has native `expect().to` with `be_a`, `be ==`, etc.)
    - `Validator::SiteTester.connected do |task, supervisor, site|` → same (library code, not test DSL)
21. Create `config/sus.rb` for sus configuration:
    - Custom config that calls `Validator.setup` (loads config, builds auto-node, etc.)
    - Override `before_tests` to start reactor + auto-node + initial connection check
    - Override `after_tests` to stop auto-node + reactor

## Phase 5: Async integration — the key simplification

22. Create `lib/rsmp/validator/async_context.rb` — a sus fixture module:
    - `around` starts/resumes the shared Async reactor, runs the test block inside it
    - No fiber-local data copying — sus doesn't use fiber-local storage
    - Connection persistence: the `Tester` singleton keeps its `@node` and `@proxy` alive across tests naturally — the reactor is never interrupted between tests
23. Include `AsyncContext` in the top-level `config/sus.rb` so all tests run inside the reactor
24. Delete all RSpec-specific reactor management (`setup_reactor`, `run_startup_checks`, `around_each` with `thread_local_data` hack)

## Phase 6: Version filtering

25. Create `lib/rsmp/validator/version_filter.rb` with helpers:
    - `Validator.sxl_matches?(requirement)` → checks `config['sxl_version']` against requirement string
    - `Validator.core_matches?(requirement)` → checks `config['core_version']` against requirement string
26. In test files, replace tag metadata with explicit skip:
    ```ruby
    it "reads S0020" do
      skip "requires sxl >= 1.0.7" unless Validator.sxl_matches?(">= 1.0.7")
      # test code
    end
    ```

## Phase 7: Executable and gem usage

27. `exe/rsmp_validator` resolves the gem's test directory via `Gem.loaded_specs['rsmp_validator'].gem_dir`
28. Final usage:
    ```
    # Auto-site (full suite):
    rsmp_validator --auto-site-config config/simulator/tlc.yaml test/site

    # Specific test:
    rsmp_validator --config config/gem_tlc.yaml test/site/tlc/modes.rb

    # Verbose output:
    rsmp_validator --auto-site-config config/simulator/tlc.yaml --verbose test/site
    ```

## Pre-migration cleanup

These are not sus-related but should be done before or during the migration:

- **Remove `proxy_type: tlc` from `config/gem_tlc.yaml`** — this config key is no longer used by the rsmp gem. The supervisor now builds a generic `SiteProxy`, and TLC-specific helpers are exposed through `site_proxy.tlc`. The key was left behind after the proxy refactoring and is harmless but misleading.

## Relevant files

### Current files to migrate (rsmp_validator/)
- `spec/support/validator.rb` → `lib/rsmp/validator.rb` — main module, strip RSpec, port to sus lifecycle
- `spec/support/validator/configuration.rb` → `lib/rsmp/validator/configuration.rb` — mostly unchanged
- `spec/support/tester.rb` → `lib/rsmp/validator/tester.rb` — remove `include RSpec::Matchers`
- `spec/support/site_tester.rb` → `lib/rsmp/validator/site_tester.rb` — unchanged logic
- `spec/support/supervisor_tester.rb` → `lib/rsmp/validator/supervisor_tester.rb` — unchanged logic
- `spec/support/auto_node.rb` → `lib/rsmp/validator/auto_node.rb` — unchanged
- `spec/support/auto_site.rb` → `lib/rsmp/validator/auto_site.rb` — unchanged
- `spec/support/auto_supervisor.rb` → `lib/rsmp/validator/auto_supervisor.rb` — unchanged
- `spec/support/config_normalizer.rb` → `lib/rsmp/validator/config_normalizer.rb` — unchanged
- `spec/support/log_helpers.rb` → `lib/rsmp/validator/log.rb` — unchanged
- `spec/support/options/*.rb` → `lib/rsmp/validator/options/*.rb` — update schema_path
- `spec/support/helpers/*.rb` → `lib/rsmp/validator/helpers/*.rb` — unchanged
- `spec/support/formatters/*.rb` → rewrite or delete

### Current test files to convert (17 site + 3 supervisor = 20 test files)
- `spec/site/core/*.rb` (4 files) → `test/site/core/*.rb`
- `spec/site/tlc/*.rb` (17 files) → `test/site/tlc/*.rb`
- `spec/supervisor/*.rb` (3 files) → `test/supervisor/*.rb`

### New files to create
- `rsmp_validator.gemspec`
- `gems.rb`
- `exe/rsmp_validator`
- `config/sus.rb` — sus configuration with validator setup
- `lib/rsmp/validator/async_context.rb` — sus fixture for shared reactor
- `lib/rsmp/validator/version_filter.rb` — sxl/core version skip helpers

### Files to delete
- `Gemfile`
- `spec/spec_helper.rb`
- `spec/support/described_types.rb`
- `spec/support/formatters/report_stream.rb` (replaced by sus output)
- `.rspec` (if exists)

### Reference files (sus framework)
- `sus/lib/sus/config.rb` — subclass for custom config
- `sus/lib/sus/base.rb` — `before`/`after`/`around` lifecycle
- `sus/lib/sus/it.rb` — test case execution
- `sus/lib/sus/context.rb` — `call(assertions)` pattern
- `sus/lib/sus/expect.rb` — `expect().to` API
- `sus/lib/sus/be.rb` — matcher predicates

## Verification

Validation is done in two stages: first against a manually started external node (simpler, no auto-node code path), then using the auto-node feature. Core tests come before TLC tests.

### Stage 1: Manual external node (no auto-node)

This verifies the basic test execution pipeline — sus runs, connects to an independently started node, tests pass.

**1a. Site (core) tests against a manually started TLC site**

Terminal 1 — start a TLC site using the rsmp gem:
```
cd rsmp
bundle exec rsmp site --config config/tlc.yaml
```

Terminal 2 — run only the core site tests:
```
cd rsmp_validator
SITE_CONFIG=config/gem_tlc.yaml bundle exec rsmp_validator test/site/core
```

Expected: connect/disconnect/aggregated_status/watchdog tests pass.

**1b. Site (TLC) tests against a manually started TLC site**

With the same site still running in Terminal 1:
```
SITE_CONFIG=config/gem_tlc.yaml bundle exec rsmp-validate test/site/tlc
```

Expected: all TLC tests pass (modes, signal groups, alarms, etc.).

**1c. Supervisor tests against a manually started supervisor**

Terminal 1 — start a supervisor:
```
cd rsmp
bundle exec rsmp supervisor --config config/supervisor.yaml
```

Terminal 2 — run supervisor tests:
```
cd rsmp_validator
SUPERVISOR_CONFIG=config/gem_supervisor.yaml bundle exec rsmp_validator test/supervisor
```

Expected: connect/aggregated_status tests pass.

---

### Stage 2: Auto-node (node started by rsmp_validator)

This verifies the auto-node infrastructure — the validator starts its own site or supervisor internally and tests against it.

**2a. Auto-site, core tests only**
```
AUTO_SITE_CONFIG=config/simulator/tlc.yaml bundle exec rsmp_validator test/site/core
```

Expected: validator starts an internal TLC site, core tests pass, site stops cleanly.

**2b. Auto-site, full site suite**
```
AUTO_SITE_CONFIG=config/simulator/tlc.yaml bundle exec rsmp_validator test/site
```

Expected: all core + TLC tests pass.

**2c. Auto-supervisor**
```
AUTO_SUPERVISOR_CONFIG=config/simulator/supervisor.yaml bundle exec rsmp_validator test/supervisor
```

Expected: all supervisor tests pass.

---

### Stage 3: Additional checks

**Single file**
```
AUTO_SITE_CONFIG=config/simulator/tlc.yaml bundle exec rsmp_validator test/site/tlc/modes.rb
```

**Version filtering** — edit `config/gem_tlc.yaml`, set `sxl_version: '1.0.7'`, then run:
```
SITE_CONFIG=config/gem_tlc.yaml bundle exec rsmp_validator test/site/tlc
```
Expected: tests tagged `sxl: '>=1.0.8'` and above are skipped.

**Verbose output**
```
AUTO_SITE_CONFIG=config/simulator/tlc.yaml bundle exec rsmp_validator --verbose test/site/core
```

**Gem packaging**
```
gem build rsmp_validator.gemspec
gem install rsmp_validator-*.gem
rsmp_validator --help
```

## Decisions
- Gem name: `rsmp_validator`, executable: `rsmp_validator`
- `rsmp_schema` stays as a separate gem (out of scope)
- `--only-failures` is explicitly not needed
- RSpec matchers are NOT used; sus has its own `expect().to` with equivalent predicates (`be_a`, `be ==`, `be :include?`, `raise_exception`, etc.)
- Tag metadata (`:sxl`, `:core`) replaced with explicit `skip` calls using helper methods
- `activesupport` dependency kept (used for `deep_merge` and time helpers)
- `described_types.rb` deleted — exists only for RuboCop RSpec cops
- Test files ship inside the gem package
- User config files are NOT in the gem — users point to their own config via CLI args or env vars
- Simulator configs (`config/simulator/`) ship in the gem for auto-node convenience
