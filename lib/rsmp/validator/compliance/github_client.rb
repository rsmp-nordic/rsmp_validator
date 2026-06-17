# frozen_string_literal: true

require 'json'
require 'net/http'
require 'open3'
require 'tmpdir'
require 'time'
require 'uri'

module RSMP
  module Validator
    module Compliance
      # Reads completed workflow runs and compliance artifacts from GitHub Actions.
      class GitHubClient
        def initialize(repo:, token:, events: %w[schedule])
          @repo = repo
          @token = token
          @events = events
        end

        def reports_since(since:)
          workflows.flat_map { |workflow| reports_for_workflow(workflow, since: since) }
        end

        private

        def workflows
          response = get_json("/repos/#{@repo}/actions/workflows", 'per_page' => '100')
          Array(response['workflows']).select { |workflow| workflow['state'] == 'active' }
        end

        def reports_for_workflow(workflow, since:)
          @events.flat_map { |event| workflow_runs(workflow.fetch('id'), event: event, since: since) }
                 .flat_map { |run| reports_for_run(run.fetch('id'), workflow) }
        end

        def reports_for_run(run_id, workflow = nil)
          report_artifacts(run_id).flat_map { |artifact| download_report_artifact(artifact) }
                                  .map { |report| enrich_workflow_metadata(report, workflow) }
        end

        def enrich_workflow_metadata(report, workflow)
          return report unless workflow

          report['workflow'] ||= {}
          report['workflow']['name'] ||= workflow['name']
          report['workflow']['file'] ||= File.basename(workflow['path'].to_s)
          report
        end

        def report_artifacts(run_id)
          run_artifacts(run_id).select { |artifact| report_artifact?(artifact) }
        end

        def report_artifact?(artifact)
          artifact['name'].start_with?('compliance-result-', 'compliance-')
        end

        def workflow_runs(workflow, event:, since:)
          response = get_json(workflow_runs_path(workflow), workflow_run_params(event))
          Array(response['workflow_runs']).select { |run| parse_time(run.fetch('created_at')) >= since }
        end

        def workflow_runs_path(workflow)
          "/repos/#{@repo}/actions/workflows/#{workflow}/runs"
        end

        def workflow_run_params(event)
          { 'branch' => 'main', 'event' => event, 'status' => 'completed', 'per_page' => '100' }
        end

        def run_artifacts(run_id)
          response = get_json("/repos/#{@repo}/actions/runs/#{run_id}/artifacts", 'per_page' => '100')
          Array(response['artifacts']).reject { |artifact| artifact['expired'] }
        end

        def download_report_artifact(artifact)
          Dir.mktmpdir('compliance-artifact') do |dir|
            download_zip(artifact.fetch('id'), File.join(dir, 'artifact.zip'))
            unzip_reports(dir)
          end
        end

        def download_zip(artifact_id, zip_path)
          path = "/repos/#{@repo}/actions/artifacts/#{artifact_id}/zip"
          run_gh_api(path, '--output', zip_path)
        end

        def unzip_reports(dir)
          zip_path = File.join(dir, 'artifact.zip')
          system('unzip', '-q', '-o', zip_path, '-d', dir) || raise("Could not unzip #{zip_path}")
          Dir[File.join(dir, '*.json')].map { |path| JSON.parse(File.read(path)) }
        end

        def get_json(path, params = {})
          response = perform_get(api_uri(path, params))
          raise_for_response(response)
          JSON.parse(response.body)
        end

        def api_uri(path, params)
          URI("https://api.github.com#{path}").tap do |uri|
            uri.query = URI.encode_www_form(params) unless params.empty?
          end
        end

        def perform_get(uri)
          Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
            http.request(request(uri))
          end
        end

        def request(uri)
          Net::HTTP::Get.new(uri).tap do |request|
            request['Accept'] = 'application/vnd.github+json'
            request['Authorization'] = "Bearer #{@token}" if @token && @token != ''
            request['X-GitHub-Api-Version'] = '2022-11-28'
          end
        end

        def raise_for_response(response)
          return if response.is_a?(Net::HTTPSuccess)

          raise "GitHub API failed: #{response.code} #{response.body}"
        end

        def run_gh_api(*args)
          output, status = Open3.capture2e({ 'GH_TOKEN' => @token }, 'gh', 'api', *args)
          raise "gh api failed: #{output}" unless status.success?
        end

        def parse_time(value)
          Time.parse(value).utc
        end
      end
    end
  end
end
