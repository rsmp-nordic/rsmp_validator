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
    @output << "  #{notification.message.colorize(:white)}\n"
  end

  def message notification # ExampleNotification
    @output << "  #{notification.message}\n"
  end

  def example_started notification # ExampleNotification
    @output <<  "#{notification.example.full_description}\n"
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
      "  #{line}"
    end.join("\n").colorize(:red)
    @output << error << "\n\n"

    backtrace = presenter.formatted_backtrace.map do |line|
      "  # #{line}"
    end.join("\n").colorize(:light_blue)
    @output << backtrace << "\n\n"
  end

  def example_pending notification # ExampleNotification
    @output << RSpec::Core::Formatters::ConsoleCodes.wrap("Pending\n\n", :pending)
  end

  def dump_pending notification # ExamplesNotification
    if notification.pending_examples.length > 0
      @output << "\n\n#{RSpec::Core::Formatters::ConsoleCodes.wrap("PENDING:", :pending)}\n\t"
      @output << notification.pending_examples.map {|example| example.full_description + " - " + example.location }.join("\n\t")
    end
  end

  def dump_failures notification # ExamplesNotification
    return
    return if notification.failed_examples.empty?
  
    @output << "\n" << "Failures:" << "\n\n"

    notification.failed_examples.each_with_index do |example, index|
      presenter = RSpec::Core::Formatters::ExceptionPresenter.new(example.execution_result.exception, example, :indentation => 0)
      @output << "  " << presenter.fully_formatted(nil) << "\n\n"

      #@output << "#{index}) #{example.full_description}\n"
      #@output << "#{index}) #{example.full_description}\n"
      #@output << "\n"
    end
  end

  def dump_summary notification # SummaryNotification
    @output << "\n\nFinished in #{RSpec::Core::Formatters::Helpers.format_duration(notification.duration)}.\n\n"


    str = "\n"
    num_errors = Validator::Testee.sentinel_errors.size
    if num_errors > 0
      e = Validator::Testee.sentinel_errors.first
      @output << "#{num_errors} sentinel warnings. First warning:\n#{e.class}: #{e}".colorize(:yellow)
    else
      @output << "No sentinel warnings."
    end
    @output << "\n\n"

    @output << "Failed examples:\n\n"

    notification.failed_examples.each do |example|
      @output << "#{example.location.colorize(:red)} " << 
        "# #{example.full_description}".colorize(:light_blue) << "\n"
    end
  end

  def close notification # NullNotification
    @output << "\n"
  end

  private


  # Joins all exception messages
  def build_examples_output output
    output.join("\n\n")
  end

  # Extracts the full_description, location and formats the message of each example exception
  def failed_example_output example
    full_description = example.full_description
    location = example.location
    formatted_message = strip_message_from_whitespace(example.execution_result.exception.message)

    "#{full_description} - #{location} \n  #{formatted_message}"
  end

  # Removes whitespace from each of the exception message lines and reformats it
  def strip_message_from_whitespace msg
    msg.split("\n").map(&:strip).join("\n#{add_spaces(10)}")
  end

  def add_spaces n
    " " * n
  end

end