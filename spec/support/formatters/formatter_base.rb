require 'rspec/core/formatters/console_codes'

class FormatterBase

  def initialize output
    @output = output
    @groups = []
  end

  def colorize str, color
    RSpec::Core::Formatters::ConsoleCodes.wrap str, color
  end

  def example_group_started notification
    @groups.push notification.group.description
  end

  def example_group_finished notification
    @groups.pop
  end

  def start notification
    @output << "\n"
  end

  def dump_pending notification
    dump_sentinel_warnings
    if notification.pending_examples.any?
      @output << notification.fully_formatted_pending_examples
    end
  end

  def dump_sentinel_warnings
      warnings = Validator::Testee.sentinel_errors
    if warnings.any?      
      @output << "\n\nSentinel warnings:\n\n"
      warnings.each.with_index(1) do |warning,i|
        @output << colorize("#{i.to_s.rjust(4)}) #{warning.class}\n",:yellow)
        @output << "      #{warning.message}\n\n"
      end
    end
  end

  def dump_failures notification
    if notification.failed_examples.any?
      @output << notification.fully_formatted_failed_examples
    end
  end

  def dump_summary notification
    @output << notification.fully_formatted

    num = Validator::Testee.sentinel_errors.size
    str = "#{num} sentinel warnings"
    str = colorize(str,:yellow) if num > 0
    @output << "\n#{str}\n "
  end

  def close notification
    @output << "\n"
  end
end