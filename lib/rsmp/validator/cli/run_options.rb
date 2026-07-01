require 'thor'

module RSMP
  module Validator
    # Parses run options that Thor leaves in the path list when options appear
    # after variadic test paths.
    class RunOptions
      FLAG_OPTIONS = {
        '--verbose' => :verbose,
        '-v' => :verbose,
        '--log' => :log_to_stdout
      }.freeze

      VALUE_OPTIONS = {
        '--log-path' => :log_path,
        '--report-json' => :report_json_path,
        '--core' => :core_version,
        '--sxls' => :sxls,
        '--site-config' => :site_config_path,
        '--supervisor-config' => :supervisor_config_path,
        '--auto-site-config' => :auto_site_config_path,
        '--auto-supervisor-config' => :auto_supervisor_config_path
      }.freeze

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
          sxls: thor_options[:sxls],
          site_config_path: thor_options[:site_config],
          supervisor_config_path: thor_options[:supervisor_config],
          auto_site_config_path: thor_options[:auto_site_config],
          auto_supervisor_config_path: thor_options[:auto_supervisor_config]
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
        flag_key = FLAG_OPTIONS[arg]
        return @parsed[flag_key] = true if flag_key

        option_key = VALUE_OPTIONS[arg]
        return @parsed[option_key] = required_option_value(arg, remaining) if option_key

        return parse_inline_value(arg) if arg.start_with?('--') && arg.include?('=')

        @parsed[:paths] << arg
      end

      def parse_inline_value(arg)
        option, value = arg.split('=', 2)
        option_key = VALUE_OPTIONS[option]
        return @parsed[option_key] = value if option_key

        @parsed[:paths] << arg
      end

      def required_option_value(option, remaining)
        value = remaining.shift
        raise Thor::Error, "#{option} requires a value" if value.nil? || value.start_with?('-')

        value
      end
    end
  end
end
