require 'thor'

module RSMP
  module Validator
    # Parses run options that Thor leaves in the path list when options appear
    # after variadic test paths.
    class RunOptions
      def self.parse(args, thor_options:)
        new(args, thor_options).parse
      end

      def initialize(args, thor_options)
        @args = args
        @parsed = {
          paths: [],
          verbose: thor_options[:verbose],
          log_to_stdout: thor_options[:log],
          log_path: thor_options[:log_path],
          report_json_path: thor_options[:report_json],
          core_version: thor_options[:core],
          sxls: thor_options[:sxls]
        }
      end

      def parse
        remaining = @args.dup
        remaining.shift if remaining.first == 'run'
        parse_remaining(remaining)
        @parsed
      end

      private

      def parse_remaining(remaining)
        parse_arg(remaining.shift, remaining) until remaining.empty?
      end

      def parse_arg(arg, remaining)
        case arg
        when '--verbose', '-v' then @parsed[:verbose] = true
        when '--log' then @parsed[:log_to_stdout] = true
        when '--log-path' then @parsed[:log_path] = required_option_value(arg, remaining)
        when /\A--log-path=(.+)\z/ then @parsed[:log_path] = Regexp.last_match(1)
        when '--report-json' then @parsed[:report_json_path] = required_option_value(arg, remaining)
        when /\A--report-json=(.+)\z/ then @parsed[:report_json_path] = Regexp.last_match(1)
        when '--core' then @parsed[:core_version] = required_option_value(arg, remaining)
        when /\A--core=(.+)\z/ then @parsed[:core_version] = Regexp.last_match(1)
        when '--sxls' then @parsed[:sxls] = required_option_value(arg, remaining)
        when /\A--sxls=(.+)\z/ then @parsed[:sxls] = Regexp.last_match(1)
        else @parsed[:paths] << arg
        end
      end

      def required_option_value(option, remaining)
        value = remaining.shift
        raise Thor::Error, "#{option} requires a value" if value.nil? || value.start_with?('-')

        value
      end
    end
  end
end
