require 'rspec/core/formatters/console_codes'

module Validator
  class FormatterBase
    def initialize(output)
      @output = output
      @groups = []
    end

    def colorize(str, color)
      RSpec::Core::Formatters::ConsoleCodes.wrap str, color
    end

    def example_group_started(notification)
      @groups.push notification.group.description
    end

    def example_group_finished(_notification)
      @groups.pop
    end

    def start(_notification)
      @output << "\n"
    end

    def dump_pending(notification)
      return unless notification.pending_examples.any?

      @output << notification.fully_formatted_pending_examples
    end

    def dump_sentinel_warnings
      warnings = Validator::Tester.sentinel_errors
      return unless warnings.any?

      @output << "\n\nSentinel warnings:\n\n"
      warnings.each.with_index(1) do |warning, i|
        @output << colorize("#{i.to_s.rjust(4)}) #{warning.class}\n", :yellow)
        @output << "      #{warning.message.capitalize}\n\n"
      end
    end

    def dump_failures(notification)
      return unless notification.failed_examples.any?

      @output << notification.fully_formatted_failed_examples
    end

    def dump_summary(notification)
      @output << notification.fully_formatted
      dump_sentinel_summary
    end

    def append_example_failure(notification)
      presenter = exception_presenter(notification)
      append_failure_message(presenter)
      append_failure_backtrace(presenter)
    end

    def dump_sentinel_summary
      return unless Validator::Tester.sentinel_errors.any?

      errors = Validator::Tester.sentinel_errors
      @output << "\n#{colorize("#{errors.size} sentinel warnings:", :yellow)}\n\n"

      errors.map(&:class).tally.each_pair do |error_class, count|
        @output << colorize("  #{count} #{error_class}\n", :yellow)
      end
    end

    def close(_notification)
      @output << "\n"
    end

    private

    def exception_presenter(notification)
      RSpec::Core::Formatters::ExceptionPresenter.new(
        notification.example.execution_result.exception,
        notification.example,
        indentation: 0
      )
    end

    def append_failure_message(presenter)
      error = presenter.message_lines.map do |line|
        colorize("  #{line}\n", :failure)
      end.join
      @output << error << "\n"
    end

    def append_failure_backtrace(presenter)
      backtrace = presenter.formatted_backtrace.map do |line|
        colorize("  # #{line}\n", :light_blue)
      end.join
      @output << backtrace << "\n"
    end
  end
end
