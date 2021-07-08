require 'active_support/time'
require 'fileutils'
require 'rsmp'

require_relative 'support/validator'
require_relative 'support/testee'
require_relative 'support/test_site'
require_relative 'support/test_supervisor'
require_relative 'support/command_helpers'
require_relative 'support/status_helpers'
require_relative 'support/log_helpers'
require_relative 'support/secrets_helpers'
require_relative 'support/formatters/report_stream.rb'
require_relative 'support/formatters/formatter_base.rb'
require_relative 'support/formatters/brief.rb'
require_relative 'support/formatters/details.rb'

include RSpec
include LogHelpers

# configure RSpec
RSpec.configure do |config|
  
  #config.reporter.message "configure"
  Validator.setup config

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do |example|
    #example.reporter.message "before suite!"
    #log "Testing started at #{Time.now}".colorize(:light_black)
  end

  # write to the validator log when each test start
  config.before(:example) do |example|
    #log "\nRunning test #{example.metadata[:location]} - #{example.full_description}".colorize(:light_black)
  end

  config.after(:suite) do |example|
    Validator.after example
    #example.reporter.message "Testing ended at #{Time.now}\n".colorize(:light_black)
  end

end