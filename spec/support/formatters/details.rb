require 'rspec/core/formatters/console_codes'

module Validator
  class Details < FormatterBase
    RSpec::Core::Formatters.register self, :start, :dump_pending, :dump_failures, :close,
      :dump_summary, :example_started, :example_passed, :example_failed, :example_pending,
      :message, :log, :step, :example_group_started, :example_group_finished

    def start notification
      @output << "\n"
    end

    def log notification
      @output << "    #{notification.message}\n"
    end

    def step notification
      @output << "  > #{notification.message}\n"
    end

    def message notification
      @output << "  #{notification.message}\n"
    end

    def example_pending notification
      @output << colorize("    Pending\n\n", :pending)
    end

    def example_started notification
      @output << colorize("#{notification.example.full_description}\n",:bold)
    end

    def example_passed notification # ExampleNotification
      @output << colorize("    Passed\n\n",:success)
    end

    def example_failed notification   
      # RSpec::Core::Formatters::ExceptionPresenter is a private class which
      # should not really be used by us, but the snippet extraction and backtrace
      # processing seems rather cumbersome to reimplement
      presenter = RSpec::Core::Formatters::ExceptionPresenter.new(notification.example.execution_result.exception, notification.example, :indentation => 0)
      
      error = presenter.message_lines.map do |line|
        colorize("  #{line}\n",:failure)
      end.join
      @output << error << "\n"

      backtrace = presenter.formatted_backtrace.map do |line|
        colorize("  # #{line}\n",:light_blue)
      end.join
      @output << backtrace << "\n"
    end
  end
end