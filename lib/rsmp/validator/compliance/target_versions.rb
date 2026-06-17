# frozen_string_literal: true

module RSMP
  module Validator
    module Compliance
      # Merges accumulated per-version state with newly observed run cells.
      class TargetVersions
        def initialize(previous:, runs:)
          @previous = previous
          @runs = runs
        end

        def to_a
          merged_versions.values.sort_by { |version| [version['core'].to_s, version['sxl'].to_s] }.reverse
        end

        private

        def merged_versions
          merged = Array(@previous).to_h { |version| [version_key(version), version] }
          @runs.each { |run| merge_run_versions(merged, run) }
          merged
        end

        def merge_run_versions(merged, run)
          run.fetch('cells', []).each do |cell|
            merged[version_key(cell)] = merge_version(merged[version_key(cell)], run, cell)
          end
        end

        def merge_version(previous, run, cell)
          latest = cell_run_summary(run, cell)
          version_fields(cell).merge(
            'last_status' => latest['status'],
            'latest_run' => latest,
            'latest_passing_run' => latest_passing_run(previous, latest)
          )
        end

        def latest_passing_run(previous, latest)
          latest['status'] == 'passed' ? latest : previous&.fetch('latest_passing_run', nil)
        end

        def version_fields(cell)
          cell.slice('core', 'sxl')
        end

        def cell_run_summary(run, cell)
          run.slice('run_id', 'run_attempt', 'run_url', 'event', 'completed_at').merge(
            cell.slice('status', 'test_count', 'failed_count', 'errored_count', 'log_artifact', 'report_artifact')
          )
        end

        def version_key(version)
          [version['core'], version['sxl']]
        end
      end
    end
  end
end
