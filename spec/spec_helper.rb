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
include Validator::LogHelpers

reactor = nil

def wait_all(task = self)
  task.children&.each do |child|
    wait_all(child)
  end
  task.wait
end

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
    reactor = Async::Reactor.new
    reactor.annotate 'reactor'
    Validator::Testee.set_reactor reactor

    # start a never-ending task.
    # he purpose of this task is to be the parents task of tasks that need to persist
    # between test, like the site/supervisor
    task = reactor.async do |task|
      task.annotate 'persistent'
      loop do
        task.sleep 1
      end
    end
    Validator::Testee.set_task task

    #Validator.check_connection
  #rescue StandardError => e
  #  STDERR.puts "Error: #{e}".colorize(:red)
  #  raise
  end

  config.after(:suite) do |example|
    puts
    reactor.stop
  end

  config.around(:each) do |example|
    reactor.run do |task|
      task.annotate 'rspec'
      example.run
    ensure
      reactor.interrupt
    end
  end

end

