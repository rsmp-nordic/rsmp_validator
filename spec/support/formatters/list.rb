require 'rspec/core/formatters/console_codes'

module Validator
  class List < FormatterBase
    RSpec::Core::Formatters.register self, :example_passed, :example_failed, :example_pending,
                                     def example_pending(notification)
                                       @output << colorize("#{notification.example.full_description}\n", :pending)
                                     end

    # ExampleNotification
    def example_passed(notification)
      @output << colorize("#{notification.example.full_description}\n", :success)
    end

    def example_failed(notification)
      @output << colorize("#{notification.example.full_description}\n", :failure)
    end
  end
end
