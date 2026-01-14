# frozen_string_literal: true

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

    def dump_sentinel_summary
      return unless Validator::Tester.sentinel_errors.any?

      num = Validator::Tester.sentinel_errors.size
      str = "#{num} sentinel warnings:"
      str = colorize(str, :yellow) if num > 0
      @output << "\n#{str}\n\n"
      Validator::Tester.sentinel_errors.dup.each_with_object(Hash.new(0)) do |x, h|
        h[x.class] += 1
      end.each_pair do |err, num|
        @output << colorize("  #{num} #{err}\n", :yellow)
      end
    end

    def close(_notification)
      @output << "\n"
    end
  end
end
