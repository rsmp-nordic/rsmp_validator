require 'rspec/core/formatters/console_codes'

#class Extra
#  RSpec::Core::Formatters.register self, :message
#  def initialize output
#    @output = output
#  end
#  def message notification # ExampleNotification
#    @output << "Extra: #{notification.message}\n"
#  end
#end

class Details
  RSpec::Core::Formatters.register self, :start, :dump_pending, :dump_failures, :close,
    :dump_summary, :example_started, :example_passed, :example_failed, :example_pending,
    :message, :log, :step

  def initialize output
    @output = output
  end

  def start notification # StartNotification
    @output << "\n"
  end

  def log notification # ExampleNotification
    @output << "    #{notification.message}\n"
  end

  def step notification # ExampleNotification
    @output << "  #{notification.message}\n"
  end

  def message notification # ExampleNotification
    @output << "  #{notification.message}\n"
  end

  def example_started notification # ExampleNotification
    @output <<  "#{notification.example.full_description}\n".bold
  end

  def example_passed notification # ExampleNotification
    @output << "  Passed\n\n".colorize(:green)
  end

  def example_failed notification # FailedExampleNotification   
    # RSpec::Core::Formatters::ExceptionPresenter is a private class which
    # should really be used by us, but the snippet extraction and backtrace
    # processing seems rather cumbersome to reimplement
    presenter = RSpec::Core::Formatters::ExceptionPresenter.new(notification.example.execution_result.exception, notification.example, :indentation => 0)
    
    error = presenter.message_lines.map do |line|
      "  #{line}\n".colorize(:red)
    end.join
    @output << error << "\n"

    backtrace = presenter.formatted_backtrace.map do |line|
      "  # #{line}\n".colorize(:light_blue)
    end.join
    @output << backtrace << "\n"
  end

  def example_pending notification # ExampleNotification
    @output << RSpec::Core::Formatters::ConsoleCodes.wrap("  Pending\n\n", :pending)
  end

  def dump_pending notification # ExamplesNotification
    #if notification.pending_examples.length > 0
    #  @output << "\n\n#{RSpec::Core::Formatters::ConsoleCodes.wrap("Pending:", :pending)}\n\n"
    #  @output << notification.pending_examples.map do |example|
    #    "  #{example.full_description } - #{example.location}\n"
    #  end.join
    #end
  end

  def dump_failures notification # ExamplesNotification
    #return if notification.failed_examples.empty?
    #@output << "\n" << "Failures:" << "\n\n"
    #notification.failed_examples.each_with_index do |example, index|
    #  presenter = RSpec::Core::Formatters::ExceptionPresenter.new(example.execution_result.exception, example, :indentation => 0)
    #  @output << "  " << presenter.fully_formatted(nil) << "\n\n"
    #end
  end

  def colorized_sentinel_warnings
    num_warnings = Validator::Testee.sentinel_errors.size
    if num_warnings > 0
      "#{num_warnings} sentinel warnings.".colorize(:yellow)
    else
      "0 sentinel warnings."
    end
  end

  def dump_summary notification # SummaryNotification
    colorizer = RSpec::Core::Formatters::ConsoleCodes
    @output << "\nFinished in #{notification.formatted_duration} " \
                "(files took #{notification.formatted_load_time} to load)\n" \
                "#{colorized_sentinel_warnings}\n" \
                "#{notification.colorized_totals_line(colorizer)}"

    if Validator::Testee.sentinel_errors.any?
      warnings = Validator::Testee.sentinel_errors.first(5)
      @output << "\nSentinel warnings: (showing #{warnings.count} of #{Validator::Testee.sentinel_errors.count}\n\n"
      warnings.each do |warning|
        @output << "#{warning.class}: #{warning}\n".colorize(:yellow)
      end
    end

    if notification.failed_examples.any?
      @output << "\n" << notification.colorized_rerun_commands(colorizer)
    end

    @output << "\n"
  end

  def close notification # NullNotification
    @output << "\n"
  end
end