# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'time'
require_relative 'report_failure'
require_relative 'report_metadata'

module RSMP
  module Validator
    module Compliance
      # Builds the machine-readable compliance report emitted by rsmp-validator.
      class Report
        DEFAULT_SCHEMA_VERSION = 1

        def initialize(assertions:, env: ENV, args: ARGV, generated_at: Time.now.utc, **options)
          @assertions = assertions
          @args = args
          @generated_at = generated_at
          @metadata = ReportMetadata.new(
            env: env,
            config: options[:config],
            log_path: options[:log_path],
            report_json_path: options[:report_json_path]
          )
        end

        def self.write(path, **options)
          report = new(**options).to_h
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, "#{JSON.pretty_generate(report)}\n")
          report
        end

        def to_h
          {
            'schema_version' => DEFAULT_SCHEMA_VERSION,
            'generated_at' => @generated_at.iso8601,
            'target' => @metadata.target,
            'workflow' => @metadata.workflow,
            'run' => @metadata.run,
            'matrix' => @metadata.matrix,
            'summary' => summary,
            'failures' => failures
          }
        end

        private

        def summary
          {
            'status' => @assertions.passed? ? 'passed' : 'failed',
            'passed' => @assertions.passed?,
            'test_count' => @assertions.total,
            'passed_count' => @assertions.passed.size,
            'failed_count' => @assertions.failed.size,
            'errored_count' => @assertions.errored.size,
            'skipped_count' => @assertions.skipped.size,
            'assertion_count' => @assertions.count
          }
        end

        def failures
          @assertions.each_failure.map { |failure| ReportFailure.new(failure).to_h }
        end
      end
    end
  end
end
