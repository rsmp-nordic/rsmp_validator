require 'thor'
require_relative '../../validator'
require_relative 'config_cli'
require_relative 'run_options'
require_relative 'runner'

module RSMP
  module Validator
    # Thor entrypoint for validator commands.
    class CLI < Thor
      desc 'run PATH...', 'Run validator conformance tests'
      method_option :verbose, type: :boolean, aliases: '-v', desc: 'Show detailed sus output'
      method_option :log, type: :boolean, desc: 'Print RSMP log output to stdout'
      method_option :log_path, type: :string, desc: 'Write RSMP log output to PATH'
      method_option :report_json, type: :string, desc: 'Write a machine-readable compliance report to PATH'
      def run_tests(*paths)
        run_options = RunOptions.parse(paths, thor_options: options)
        if run_options[:log_to_stdout] && run_options[:log_path]
          raise Thor::Error, '--log and --log-path cannot be used together'
        end

        status = Runner.new(
          paths: run_options[:paths],
          verbose: run_options[:verbose],
          log_to_stdout: run_options[:log_to_stdout],
          log_path: run_options[:log_path],
          report_json_path: run_options[:report_json_path]
        ).run
        exit status
      end
      map 'run' => :run_tests

      register ConfigCLI, 'config', 'config COMMAND', 'Configuration commands'

      def self.exit_on_failure?
        true
      end
    end
  end
end
