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
      method_option :core, type: :string, desc: 'Override RSMP Core version for this run'
      method_option :sxls, type: :string, desc: 'Override SXL versions as name:version,...'
      method_option :site_config, type: :string, desc: 'Use PATH as the site test config'
      method_option :supervisor_config, type: :string, desc: 'Use PATH as the supervisor test config'
      method_option :auto_site_config, type: :string, desc: 'Use PATH as the auto site config'
      method_option :auto_supervisor_config, type: :string, desc: 'Use PATH as the auto supervisor config'
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
          report_json_path: run_options[:report_json_path],
          core_version: run_options[:core_version],
          sxls: run_options[:sxls],
          site_config_path: run_options[:site_config_path],
          supervisor_config_path: run_options[:supervisor_config_path],
          auto_site_config_path: run_options[:auto_site_config_path],
          auto_supervisor_config_path: run_options[:auto_supervisor_config_path]
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
