# frozen_string_literal: true

require 'fileutils'
require 'time'
require_relative 'compliance_data_store'
require_relative 'github_client'
require_relative 'run_builder'
require_relative 'summary'

module RSMP
  module Validator
    module Compliance
      # Coordinates collecting GitHub artifacts and writing static compliance data.
      class Collector
        DEFAULT_LOOKBACK_DAYS = 45
        DEFAULT_OVERLAP_DAYS = 3
        SECONDS_PER_DAY = 24 * 60 * 60

        def initialize(github:, website_dir:, data_dir:, source_repo:, **options)
          @github = github
          @website_dir = website_dir
          @source_repo = source_repo
          @now = options.key?(:now) ? options[:now] : Time.now.utc
          @lookback_days = options.fetch(:lookback_days, DEFAULT_LOOKBACK_DAYS)
          @overlap_days = options.fetch(:overlap_days, DEFAULT_OVERLAP_DAYS)
          @full = options.fetch(:full, false)
          @store = ComplianceDataStore.new(data_dir)
        end

        def collect
          previous_summary = @full ? empty_summary : @store.read_summary
          reports = @github.reports_since(since: since_for(previous_summary))
          targets = targets_from_reports(reports)
          runs = runs_by_target(targets, reports)
          summary = Summary.new(
            targets: targets,
            runs_by_target: runs,
            previous_summary: previous_summary,
            now: @now
          ).to_h
          write_data(summary, runs)
          summary
        end

        private

        def runs_by_target(targets, reports)
          targets.to_h do |target|
            target_reports = reports.select { |report| report.dig('target', 'id') == target.fetch('id') }
            [target.fetch('id'), RunBuilder.new(target, target_reports).runs]
          end
        end

        def targets_from_reports(reports)
          reports.group_by { |report| report.dig('target', 'id') }.filter_map do |_id, target_reports|
            target_from_reports(target_reports)
          end
        end

        def target_from_reports(reports)
          report = reports.find { |candidate| candidate.dig('target', 'id') }
          return nil unless report

          target = report.fetch('target').compact
          workflow_file = report.dig('workflow', 'file')
          target.merge(
            'workflow_file' => workflow_file,
            'workflow_name' => report.dig('workflow', 'name'),
            'details_url' => details_url(workflow_file)
          ).compact
        end

        def details_url(workflow_file)
          return nil unless workflow_file

          "https://github.com/#{@source_repo}/actions/workflows/#{workflow_file}?query=branch%3Amain+event%3Aschedule"
        end

        def since_for(previous_summary)
          latest = latest_completed_at(previous_summary)
          return lookback_start unless latest && !@full

          latest - (@overlap_days * SECONDS_PER_DAY)
        end

        def latest_completed_at(summary)
          Array(summary['targets']).filter_map do |target|
            parse_time(target.dig('latest_run', 'completed_at'))
          end.max
        end

        def lookback_start
          @now - (@lookback_days * SECONDS_PER_DAY)
        end

        def write_data(summary, runs)
          @store.write_summary(summary)
          runs.each { |target_id, target_runs| target_runs.each { |run| @store.write_run(target_id, run) } }
          write_website_summary(summary)
        end

        def write_website_summary(summary)
          data_dir = File.join(@website_dir, '_data', 'compliance')
          FileUtils.mkdir_p(data_dir)
          File.write(File.join(data_dir, 'summary.json'), "#{JSON.pretty_generate(summary)}\n")
        end

        def empty_summary
          { 'generated_at' => nil, 'targets' => [] }
        end

        def parse_time(value)
          return nil unless value

          Time.parse(value).utc
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
