# frozen_string_literal: true

require 'rspec/core/formatters/console_codes'

module Validator
  class Steps < FormatterBase
    RSpec::Core::Formatters.register(
      self,
      :start,
      :dump_pending,
      :dump_failures,
      :close,
      :dump_summary,
      :example_started,
      :example_passed,
      :example_failed,
      :example_pending,
      :message,
      :warning,
      :step,
      :example_group_started,
      :example_group_finished
    )

    def start(_notification)
      @output << "\n"
    end

    def warning(notification)
      @output << colorize("    Warning: #{notification.message}\n", :yellow)
    end

    def step(notification)
      @output << colorize("    #{notification.message}\n", :cyan)
    end

    def message(notification)
      @output << "  #{notification.message}\n"
    end

    def example_pending(_notification)
      @output << colorize("    Pending\n\n", :pending)
    end

    def example_started(notification)
      @output << colorize("\n#{notification.example.full_description}\n", :bold)
    end

    # ExampleNotification
    def example_passed(_notification)
      @output << colorize("    Passed\n\n", :success)
    end

    def example_failed(notification)
      # RSpec::Core::Formatters::ExceptionPresenter is a private class which
      # should not really be used by us, but the snippet extraction and backtrace
      # processing seems rather cumbersome to reimplement
      presenter = RSpec::Core::Formatters::ExceptionPresenter.new(notification.example.execution_result.exception,
                                                                  notification.example, indentation: 0)

      error = presenter.message_lines.map do |line|
        colorize("  #{line}\n", :failure)
      end.join
      @output << error << "\n"

      backtrace = presenter.formatted_backtrace.map do |line|
        colorize("  # #{line}\n", :light_blue)
      end.join
      @output << backtrace << "\n"
    end

    def dump_pending(notification)
      dump_sentinel_warnings
      super
    end
  end
end
