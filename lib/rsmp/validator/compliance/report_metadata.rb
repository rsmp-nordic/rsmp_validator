# frozen_string_literal: true

require_relative 'config_metadata'
require_relative 'config_sxls'

module RSMP
  module Validator
    module Compliance
      # Builds static and runtime metadata for a compliance report.
      class ReportMetadata
        def initialize(env:, config: nil, log_path: nil, report_json_path: nil)
          @env = env
          @config = config
          @log_path = log_path
          @report_json_path = report_json_path
        end

        def target
          ConfigMetadata.new(config_path).target.merge(env_target_metadata)
        end

        def workflow
          env_hash(
            'name' => 'GITHUB_WORKFLOW',
            'file' => 'COMPLIANCE_WORKFLOW_FILE',
            'event' => 'GITHUB_EVENT_NAME',
            'ref' => 'GITHUB_REF',
            'sha' => 'GITHUB_SHA'
          ).merge(workflow_file_from_ref)
        end

        def run
          {
            'id' => integer_env('GITHUB_RUN_ID'),
            'number' => integer_env('GITHUB_RUN_NUMBER'),
            'attempt' => integer_env('GITHUB_RUN_ATTEMPT'),
            'url' => run_url,
            'log_artifact' => env_value('COMPLIANCE_LOG_ARTIFACT') || @log_path,
            'report_artifact' => env_value('COMPLIANCE_REPORT_ARTIFACT') || @report_json_path
          }.compact
        end

        def matrix
          values = {
            'core' => config_value('core_version') || env_value('CORE_VERSION'),
            'os' => env_value('RUNNER_OS')
          }.compact
          sxls = ConfigSxls.new(@config).to_h
          values['sxls'] = sxls unless sxls.empty?
          values
        end

        private

        def env_target_metadata
          env_hash(
            'id' => 'COMPLIANCE_TARGET_ID',
            'kind' => 'COMPLIANCE_TARGET_KIND',
            'name' => 'COMPLIANCE_TARGET_NAME',
            'product_url' => 'COMPLIANCE_PRODUCT_URL'
          )
        end

        def workflow_file_from_ref
          workflow_ref = env_value('GITHUB_WORKFLOW_REF')
          match = workflow_ref&.match(%r{/(\.github/workflows/[^@]+)@})
          match ? { 'file' => File.basename(match[1]) } : {}
        end

        def env_hash(mapping)
          mapping.transform_values { |name| env_value(name) }.compact
        end

        def config_path
          env_value('SITE_CONFIG') || env_value('SUPERVISOR_CONFIG')
        end

        def config_value(name)
          @config[name] if @config.is_a?(Hash)
        end

        def integer_env(name)
          value = env_value(name)
          value&.to_i
        end

        def env_value(name)
          value = @env[name]
          value unless value.nil? || value == ''
        end

        def run_url
          repository = env_value('GITHUB_REPOSITORY')
          run_id = env_value('GITHUB_RUN_ID')
          return nil unless repository && run_id

          "https://github.com/#{repository}/actions/runs/#{run_id}"
        end
      end
    end
  end
end
