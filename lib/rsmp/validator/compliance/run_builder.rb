# frozen_string_literal: true

require 'time'

module RSMP
  module Validator
    module Compliance
      # Builds normalized matrix-run records from individual result artifacts.
      class RunBuilder
        def initialize(target, reports)
          @target = target
          @reports = reports
        end

        def runs
          grouped_reports.map { |run_key, cells| build_run(run_key, cells) }
                         .sort_by { |run| [run['completed_at'] || '', run['run_attempt'].to_i] }
                         .reverse
        end

        private

        def grouped_reports
          @reports.group_by { |report| [report.dig('run', 'id'), report.dig('run', 'attempt')] }
        end

        def build_run(run_key, cells)
          normalized_cells = normalized_cells(cells)
          {
            'target_id' => @target.fetch('id'),
            'run_id' => run_key.first,
            'run_attempt' => run_key.last,
            'run_url' => first_value(cells, 'run', 'url'),
            'event' => first_value(cells, 'workflow', 'event'),
            'completed_at' => completed_at(cells),
            'status' => run_status(normalized_cells),
            'passed_cells' => normalized_cells.count { |cell| cell['status'] == 'passed' },
            'total_cells' => normalized_cells.size,
            'cells' => normalized_cells
          }
        end

        def normalized_cells(cells)
          return expected_cells.map { |expected| normalized_expected_cell(cells, expected) } if expected_cells.any?

          cells.map { |report| cell_summary(report) }.sort_by { |cell| [cell['core'].to_s, cell['sxl'].to_s] }
        end

        def expected_cells
          Array(@target['expected_cells'])
        end

        def normalized_expected_cell(cells, expected_cell)
          report = cells.find { |cell| cell_matches?(cell, expected_cell) }
          report ? cell_summary(report) : expected_cell.merge('status' => 'missing')
        end

        def cell_matches?(report, expected_cell)
          expected_cell.all? { |key, value| report.dig('matrix', key) == value }
        end

        def cell_summary(report)
          {
            'core' => report.dig('matrix', 'core'),
            'sxl' => report.dig('matrix', 'sxl'),
            'status' => report.dig('summary', 'status') || 'failed',
            'test_count' => report.dig('summary', 'test_count'),
            'failed_count' => report.dig('summary', 'failed_count'),
            'errored_count' => report.dig('summary', 'errored_count'),
            'log_artifact' => report.dig('run', 'log_artifact'),
            'report_artifact' => report.dig('run', 'report_artifact'),
            'failures' => Array(report['failures']).first(10)
          }.compact
        end

        def completed_at(cells)
          cells.map { |cell| parse_time(cell['generated_at']) }.compact.max&.iso8601
        end

        def first_value(cells, *path)
          cells.find { |cell| cell.dig(*path) }&.dig(*path)
        end

        def run_status(cells)
          cells.all? { |cell| cell['status'] == 'passed' } ? 'passed' : 'failed'
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
