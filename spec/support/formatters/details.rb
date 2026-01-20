require 'rspec/core/formatters/console_codes'

module Validator
  class Details < FormatterBase
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
      :log,
      :warning,
      :step,
      :example_group_started,
      :example_group_finished
    )

    def start(_notification)
      @output << "\n"
    end

    def log(notification)
      @output << "    #{notification.message}\n"
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
      append_example_failure(notification)
    end

    def dump_pending(notification)
      dump_sentinel_warnings
      super
    end
  end
end
