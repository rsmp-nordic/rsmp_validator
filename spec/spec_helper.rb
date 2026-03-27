require 'async'
require 'active_support'
require 'active_support/time'
require 'fileutils'
require 'rsmp'

require_relative 'support/validator'
require_relative 'support/tester'
require_relative 'support/site_tester'
require_relative 'support/supervisor_tester'
require_relative 'support/auto_node'
require_relative 'support/auto_site'
require_relative 'support/auto_supervisor'
require_relative 'support/helpers/commands'
require_relative 'support/helpers/status'
require_relative 'support/helpers/input'
require_relative 'support/helpers/clock'
require_relative 'support/helpers/security'
require_relative 'support/helpers/signal_plans'
require_relative 'support/helpers/alarms'
require_relative 'support/helpers/startup'
require_relative 'support/helpers/handshake'
require_relative 'support/helpers/signal_priority'
require_relative 'support/described_types'
require_relative 'support/log_helpers'
require_relative 'support/formatters/report_stream'
require_relative 'support/formatters/formatter_base'
require_relative 'support/formatters/brief'
require_relative 'support/formatters/details'
require_relative 'support/formatters/list'
require_relative 'support/formatters/steps'

# configure RSpec
RSpec.configure do |config|
  config.include Validator::Log

  Validator.setup config

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do |example|
    Validator.before_suite example
  end

  config.around do |example|
    Validator.around_each example
  end
end
