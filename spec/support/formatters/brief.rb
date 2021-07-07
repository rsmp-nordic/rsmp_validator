require 'rspec/core/formatters/console_codes'

class Brief < FormatterBase
  RSpec::Core::Formatters.register self, :start, :dump_pending, :dump_failures, :close,
    :dump_summary, :example_passed, :example_failed, :example_pending,
    :example_group_started, :example_group_finished

  def indent
    ' '*(@groups.count*2)
  end

  def example_group_started notification
    @output <<  "#{indent}#{notification.group.description}\n"
    super
  end

  def example_group_finished notification
    super
    @output << "\n" if @groups.empty?
  end

  def example_passed notification
    @output <<  colorize("#{indent}#{notification.example.description}\n",:success)
  end

  def example_failed notification   
    @output << colorize("#{indent}#{notification.example.description}",:failure)
    @output << colorize(" - Failed: #{notification.example.execution_result.exception}\n",:light_black) 
  end

  def example_pending notification
    @output << colorize("#{indent}#{notification.example.description} - " \
      "Pending: #{notification.example.execution_result.pending_message}\n",:pending)
  end
end