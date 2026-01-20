require 'rspec/core/formatters/console_codes'

module Validator
  class Brief < FormatterBase
    RSpec::Core::Formatters.register self, :start, :dump_pending, :dump_failures, :close,
                                     :dump_summary, :example_passed, :example_failed, :example_pending,
                                     :example_group_started, :example_group_finished, :warning

    def indent
      ' ' * (@groups.count * 2)
    end

    def warning(notification)
      @output << colorize("    Warning: #{notification.message}\n", :yellow)
    end

    def example_group_started(notification)
      @output << "#{indent}#{notification.group.description}\n"
      super
    end

    def example_group_finished(notification)
      super
      @output << "\n" if @groups.empty?
    end

    def example_passed(notification)
      @output << colorize("#{indent}#{notification.example.description}\n", :success)
    end

    def example_failed(notification)
      @output << colorize("#{indent}#{notification.example.description}", :failure)

      # expect { }.not_to raise_error might raise an RSpec::Expectations::ExpectationNotMetError,
      # with a messager that includes a backtrace. we don't want to show that here, so remove it
      message = notification.example.execution_result.exception.message.strip
                            .gsub(/^\s+/, '')
                            .gsub(/\n+/, ', ')
                            .sub(/\s+with backtrace:.*/m, '')
      @output << colorize(" - Failed: #{message}\n", :white)
    end

    def example_pending(notification)
      @output << colorize("#{indent}#{notification.example.description} - " \
                          "Pending: #{notification.example.execution_result.pending_message}\n", :pending)
    end

    def dump_failures(notification); end
  end
end
