# frozen_string_literal: true

require 'time'
require_relative 'run_builder'
require_relative 'target_summary'

module RSMP
  module Validator
    module Compliance
      # Computes and merges website-ready compliance summaries.
      class Summary
        def initialize(targets: [], reports: nil, runs_by_target: nil, previous_summary: nil, now: Time.now.utc)
          @targets = targets
          @reports = reports || []
          @runs_by_target = runs_by_target
          @previous_summary = previous_summary || { 'targets' => [] }
          @now = now
        end

        def to_h
          { 'generated_at' => @now.iso8601, 'targets' => summarized_targets }
        end

        private

        def summarized_targets
          runs = runs_by_target
          all_targets.map { |target| summarize_target(target, runs[target.fetch('id')] || []) }
                     .sort_by { |target| [target['kind'].to_s, target['name'].to_s] }
        end

        def summarize_target(target, runs)
          TargetSummary.new(
            target: target,
            previous: previous_target(target.fetch('id')) || {},
            runs: runs,
            now: @now
          ).to_h
        end

        def runs_by_target
          @runs_by_target || build_runs_by_target
        end

        def build_runs_by_target
          @targets.to_h do |target|
            [target.fetch('id'), RunBuilder.new(target, reports_for(target)).runs]
          end
        end

        def reports_for(target)
          @reports.select { |report| report.dig('target', 'id') == target.fetch('id') }
        end

        def all_targets
          merged = previous_targets.to_h { |target| [target.fetch('id'), public_target_fields(target)] }
          @targets.each { |target| merge_target(merged, target) }
          merged.values
        end

        def merge_target(merged, target)
          target_id = target.fetch('id')
          merged[target_id] = merged.fetch(target_id, {}).merge(public_target_fields(target))
        end

        def previous_targets
          Array(@previous_summary['targets'])
        end

        def previous_target(target_id)
          previous_targets.find { |target| target['id'] == target_id }
        end

        def public_target_fields(target)
          target.except('expected_cells')
        end
      end
    end
  end
end
