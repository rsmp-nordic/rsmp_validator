require 'sus'
require 'sus/config'
require_relative '../compliance/report'
require_relative 'tee_io'

module RSMP
  module Validator
    # Runs the conformance test suite through Sus while preserving validator
    # specific options that Sus does not know about.
    class Runner
      def initialize(paths:, verbose:, log_to_stdout:, log_path:, report_json_path:, core_version:, sxls:,
                     site_config_path:, supervisor_config_path:, auto_site_config_path:,
                     auto_supervisor_config_path:)
        @paths = paths
        @verbose = verbose
        @log_to_stdout = log_to_stdout
        @log_path = log_path
        @report_json_path = report_json_path
        @core_version = core_version
        @sxls = sxls
        @site_config_path = site_config_path
        @supervisor_config_path = supervisor_config_path
        @auto_site_config_path = auto_site_config_path
        @auto_supervisor_config_path = auto_supervisor_config_path
      end

      def run
        with_argv(sus_args) { run_with_args }
      end

      private

      def run_with_args
        RSMP::Validator.core_version_override = @core_version
        RSMP::Validator.sxls_override = @sxls
        RSMP::Validator.site_config_path = @site_config_path
        RSMP::Validator.supervisor_config_path = @supervisor_config_path
        RSMP::Validator.auto_site_config_path = @auto_site_config_path
        RSMP::Validator.auto_supervisor_config_path = @auto_supervisor_config_path
        config = validator_config_class.load
        config.log_to_stdout = @log_to_stdout
        config.log_path = @log_path

        registry = config.registry
        return run_with_log_file(config, registry) if @log_path && config.verbose?

        run_with_default_output(config, registry)
      ensure
        RSMP::Validator.core_version_override = nil
        RSMP::Validator.sxls_override = nil
        RSMP::Validator.site_config_path = nil
        RSMP::Validator.supervisor_config_path = nil
        RSMP::Validator.auto_site_config_path = nil
        RSMP::Validator.auto_supervisor_config_path = nil
        RSMP::Validator.config_path = nil
      end

      def sus_args
        args = @paths.dup
        args << '--verbose' if @verbose
        args
      end

      def with_argv(args)
        original = ARGV.dup
        ARGV.replace(args)
        yield
      ensure
        ARGV.replace(original)
      end

      def validator_config_class
        Class.new(Sus::Config) do
          attr_accessor :log_to_stdout, :log_path, :log_file_io

          def self.path(root)
            path = File.join(root, 'config/validator.rb')
            File.exist?(path) ? path : nil
          end
        end
      end

      def run_with_log_file(config, registry)
        File.open(@log_path, 'w') do |log_file|
          config.log_path = nil
          config.log_file_io = log_file
          output = Sus::Output.default(TeeIO.new($stderr, log_file))
          run_suite(config, registry, output, true)
        end
      end

      def run_with_default_output(config, registry)
        output = config.verbose? ? config.output : Sus::Output::Null.new
        run_suite(config, registry, output, config.verbose?)
      end

      def run_suite(config, registry, output, verbose)
        assertions = Sus::Assertions.default(output: output, verbose: verbose)
        begin
          config.before_tests(assertions)
          registry.call(assertions)
        ensure
          config.after_tests(assertions)
        end
        write_report(assertions)
        assertions.passed? ? 0 : 1
      end

      def write_report(assertions)
        return unless @report_json_path

        RSMP::Validator::Compliance::Report.write(
          @report_json_path,
          assertions: assertions,
          env: ENV,
          args: @paths,
          config: RSMP::Validator.config,
          config_path: RSMP::Validator.config_path,
          log_path: @log_path,
          report_json_path: @report_json_path
        )
      end
    end
  end
end
