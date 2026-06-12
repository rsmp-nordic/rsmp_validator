require 'async'
require 'active_support'
require 'active_support/time'
require 'fileutils'
require_relative '../lib/rsmp/validator'

# Include RSMP::Validator::Log in all test instances so log() is available in all tests
Sus::Base.include(RSMP::Validator::Log)

# Include Connection helpers so with_site/with_supervisor are available in all tests
Sus::Base.include(RSMP::Validator::Helpers::Connection)

# Include AsyncContext so all tests run inside the shared reactor
Sus::Base.prepend(RSMP::Validator::AsyncContext)

# Add eq helper: wraps sus's `be ==` so spec files can use eq(x) for value equality
Sus::Base.define_method(:eq) { |value| be == value }

# Conformance test paths: test/site/ and test/supervisor/
def test_paths
  Dir.glob('test/site/**/*.rb', base: @root) +
    Dir.glob('test/supervisor/**/*.rb', base: @root)
end

# Called before tests are run: set up reactor, auto-node, initial connection
def before_tests(assertions, output: self.output)
  super

  RSMP::Validator.setup(self)
  RSMP::Validator.before_suite
end

# Called after tests are run: stop auto-node and reactor
def after_tests(assertions, output: self.output)
  RSMP::Validator.after_suite
  super
end
