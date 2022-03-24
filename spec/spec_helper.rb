require 'async'
require 'active_support/time'
require 'fileutils'
require 'rsmp'

require_relative 'support/validator'
require_relative 'support/testee'
require_relative 'support/test_site'
require_relative 'support/test_supervisor'
require_relative 'support/command_helpers'
require_relative 'support/status_helpers'
require_relative 'support/sequence_helper'
require_relative 'support/log_helpers'
require_relative 'support/formatters/report_stream.rb'
require_relative 'support/formatters/formatter_base.rb'
require_relative 'support/formatters/brief.rb'
require_relative 'support/formatters/details.rb'
require_relative 'support/formatters/list.rb'

include RSpec
include Validator::Log

# configure RSpec
RSpec.configure do |config|
  Validator.setup config

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do |example|
    Validator.before_suite example
  end

  config.around(:each) do |example|
    Validator.around_each example
  end
end
