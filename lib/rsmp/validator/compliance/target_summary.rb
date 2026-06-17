# frozen_string_literal: true

require 'time'
require_relative 'target_versions'

module RSMP
  module Validator
    module Compliance
      # Merges previous target state with newly observed runs.
      class TargetSummary
        SECONDS_PER_DAY = 24 * 60 * 60

        def initialize(target:, previous:, runs:, now: Time.now.utc)
          @target = target
          @previous = previous
          @runs = runs
          @now = now
        end

        def to_h
          @target.merge(
            'latest_run' => latest_run,
            'latest_passing_run' => latest_passing_run,
            'best_run' => best_run,
            'last_30_days' => last_month_stats,
            'passed_versions' => passed_versions,
            'versions' => versions,
            'recent_runs' => recent_runs
          )
        end

        private

        def latest_run
          latest_record([@previous['latest_run'], *@runs])
        end

        def latest_passing_run
          latest_record([@previous['latest_passing_run'], *new_passing_runs])
        end

        def new_passing_runs
          @runs.select { |run| run['status'] == 'passed' }
        end

        def best_run
          latest_passing_run || best_partial_run([@previous['best_run'], *@runs].compact)
        end

        def recent_runs
          @recent_runs ||= sort_runs(recent_run_values.select { |run| within_last_month?(run['completed_at']) })
        end

        def recent_run_values
          merged = Array(@previous['recent_runs']).to_h { |run| [run_key(run), run] }
          @runs.each { |run| merged[run_key(run)] = compact_run(run) }
          merged.values
        end

        def compact_run(run)
          run.slice('target_id', 'run_id', 'run_attempt', 'run_url', 'event', 'completed_at', 'status', 'passed_cells',
                    'total_cells')
        end

        def versions
          @versions ||= TargetVersions.new(previous: @previous['versions'], runs: @runs).to_a
        end

        def passed_versions
          versions.select { |version| version['latest_passing_run'] }.map { |version| version.slice('core', 'sxl') }
        end

        def last_month_stats
          total = recent_runs.sum { |run| run['total_cells'].to_i }
          passed = recent_runs.sum { |run| run['passed_cells'].to_i }
          { 'passed_cells' => passed, 'total_cells' => total, 'pass_percentage' => pass_percentage(passed, total) }
        end

        def pass_percentage(passed, total)
          return nil unless total.positive?

          ((passed.to_f / total) * 100).round(1)
        end

        def latest_record(records)
          records.compact.max_by { |record| [record['completed_at'] || '', record['run_attempt'].to_i] }
        end

        def best_partial_run(runs)
          runs.max_by { |run| [pass_ratio(run), run['completed_at'] || ''] }
        end

        def pass_ratio(run)
          total = run['total_cells'].to_i
          total.positive? ? run['passed_cells'].to_f / total : 0.0
        end

        def sort_runs(runs)
          runs.sort_by { |run| [run['completed_at'] || '', run['run_attempt'].to_i] }.reverse
        end

        def within_last_month?(time)
          parsed = parse_time(time)
          parsed && parsed >= @now - (30 * SECONDS_PER_DAY)
        end

        def run_key(run)
          [run['run_id'], run['run_attempt']]
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
