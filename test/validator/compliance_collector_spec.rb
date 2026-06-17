require 'json'
require 'tmpdir'
require_relative '../../lib/rsmp/validator/compliance/collector'

module ComplianceCollectorSpec
  class FakeGitHub
    attr_reader :since_values

    def initialize(reports)
      @reports = reports
      @since_values = []
    end

    def reports_since(since:)
      @since_values << since
      @reports
    end
  end

  module_function

  def target
    {
      'id' => 'demo',
      'kind' => 'site',
      'name' => 'Demo TLC',
      'product_url' => 'https://example.test/demo',
      'workflow_file' => 'demo.yaml',
      'details_url' => 'https://github.com/rsmp-nordic/rsmp_validator/actions/workflows/demo.yaml?query=branch%3Amain+event%3Aschedule'
    }
  end

  def previous_summary
    {
      'generated_at' => '2026-06-16T08:00:00Z',
      'targets' => [
        target.merge(
          'latest_run' => run_summary(1, 'failed', '2026-06-10T00:00:00Z', 1),
          'latest_passing_run' => nil,
          'best_run' => run_summary(1, 'failed', '2026-06-10T00:00:00Z', 1),
          'last_30_days' => { 'passed_cells' => 1, 'total_cells' => 2, 'pass_percentage' => 50.0 },
          'passed_versions' => [{ 'core' => '3.2.2', 'sxl' => '1.2.1' }],
          'versions' => [version_summary('3.2.2', 'passed', '2026-06-10T00:00:00Z')],
          'recent_runs' => [run_summary(1, 'failed', '2026-06-10T00:00:00Z', 1)]
        )
      ]
    }
  end

  def report(run_id, attempt, core, status, generated_at)
    {
      'generated_at' => generated_at,
      'target' => target.slice('id', 'kind', 'name', 'product_url'),
      'workflow' => { 'name' => 'Demo', 'file' => 'demo.yaml', 'event' => 'schedule' },
      'run' => { 'id' => run_id, 'attempt' => attempt, 'url' => "https://example.test/#{run_id}" },
      'matrix' => { 'core' => core, 'sxl' => '1.2.1' },
      'summary' => { 'status' => status, 'test_count' => 10, 'failed_count' => failed_count(status) }
    }
  end

  def run_summary(run_id, status, completed_at, passed_cells)
    {
      'target_id' => 'demo',
      'run_id' => run_id,
      'run_attempt' => 1,
      'run_url' => "https://example.test/#{run_id}",
      'event' => 'schedule',
      'completed_at' => completed_at,
      'status' => status,
      'passed_cells' => passed_cells,
      'total_cells' => 2
    }
  end

  def version_summary(core, status, completed_at)
    run = {
      'run_id' => 1,
      'run_attempt' => 1,
      'run_url' => 'https://example.test/1',
      'event' => 'schedule',
      'completed_at' => completed_at,
      'status' => status
    }
    {
      'core' => core,
      'sxl' => '1.2.1',
      'last_status' => status,
      'latest_run' => run,
      'latest_passing_run' => status == 'passed' ? run : nil
    }
  end

  def failed_count(status)
    status == 'passed' ? 0 : 1
  end
end

describe RSMP::Validator::Compliance::Summary do
  it 'merges latest and latest passing runs from previous summary and new runs' do
    runs = {
      'demo' => [
        {
          'target_id' => 'demo',
          'run_id' => 2,
          'run_attempt' => 1,
          'run_url' => 'https://example.test/2',
          'event' => 'schedule',
          'completed_at' => '2026-06-17T00:00:01Z',
          'status' => 'passed',
          'passed_cells' => 2,
          'total_cells' => 2,
          'cells' => [
            { 'core' => '3.2.2', 'sxl' => '1.2.1', 'status' => 'passed' },
            { 'core' => '3.3.0', 'sxl' => '1.2.1', 'status' => 'passed' }
          ]
        }
      ]
    }

    summary = RSMP::Validator::Compliance::Summary.new(
      targets: [ComplianceCollectorSpec.target],
      runs_by_target: runs,
      previous_summary: ComplianceCollectorSpec.previous_summary,
      now: Time.utc(2026, 6, 17, 8, 0, 0)
    ).to_h['targets'].first

    expect(summary['latest_run']['run_id']).to be == 2
    expect(summary['latest_passing_run']['run_id']).to be == 2
    expect(summary['passed_versions']).to be == [
      { 'core' => '3.3.0', 'sxl' => '1.2.1' },
      { 'core' => '3.2.2', 'sxl' => '1.2.1' }
    ]
    expect((summary['last_30_days']['pass_percentage'] - 75.0).abs < 0.01).to be == true
  end

  it 'keeps an older latest pass when the new run fails' do
    runs = {
      'demo' => [
        ComplianceCollectorSpec.run_summary(2, 'failed', '2026-06-17T00:00:01Z', 1).merge(
          'cells' => [{ 'core' => '3.2.2', 'sxl' => '1.2.1', 'status' => 'failed' }]
        )
      ]
    }

    summary = RSMP::Validator::Compliance::Summary.new(
      targets: [ComplianceCollectorSpec.target],
      runs_by_target: runs,
      previous_summary: ComplianceCollectorSpec.previous_summary,
      now: Time.utc(2026, 6, 17, 8, 0, 0)
    ).to_h['targets'].first

    expect(summary['latest_run']['run_id']).to be == 2
    expect(summary['latest_passing_run'].nil?).to be == true
    expect(summary['versions'].first['latest_passing_run']['run_id']).to be == 1
  end
end

describe RSMP::Validator::Compliance::Collector do
  it 'uses the data branch summary as state and writes new run summaries' do
    Dir.mktmpdir do |website_dir|
      Dir.mktmpdir do |data_dir|
        File.write(File.join(data_dir, 'summary.json'),
                   "#{JSON.pretty_generate(ComplianceCollectorSpec.previous_summary)}\n")
        github = ComplianceCollectorSpec::FakeGitHub.new([
                                                           ComplianceCollectorSpec.report(2, 1, '3.2.2', 'passed',
                                                                                          '2026-06-17T00:00:00Z'),
                                                           ComplianceCollectorSpec.report(2, 1, '3.3.0', 'passed',
                                                                                          '2026-06-17T00:00:01Z')
                                                         ])

        data = RSMP::Validator::Compliance::Collector.new(
          github: github,
          website_dir: website_dir,
          data_dir: data_dir,
          source_repo: 'rsmp-nordic/rsmp_validator',
          now: Time.utc(2026, 6, 17, 8, 0, 0)
        ).collect

        expect(github.since_values.first).to be == Time.utc(2026, 6, 7, 0, 0, 0)
        expect(data['targets'].first['latest_run']['run_id']).to be == 2
        expect(File.exist?(File.join(data_dir, 'runs/demo/2-1.json'))).to be == true
        expect(File.exist?(File.join(website_dir, '_data/compliance/summary.json'))).to be == true
      end
    end
  end

  it 'ignores previous data branch summary in full mode' do
    Dir.mktmpdir do |website_dir|
      Dir.mktmpdir do |data_dir|
        File.write(File.join(data_dir, 'summary.json'),
                   "#{JSON.pretty_generate(ComplianceCollectorSpec.previous_summary)}\n")
        github = ComplianceCollectorSpec::FakeGitHub.new([
                                                           ComplianceCollectorSpec.report(2, 1, '3.2.2', 'passed',
                                                                                          '2026-06-17T00:00:00Z')
                                                         ])

        data = RSMP::Validator::Compliance::Collector.new(
          github: github,
          website_dir: website_dir,
          data_dir: data_dir,
          source_repo: 'rsmp-nordic/rsmp_validator',
          now: Time.utc(2026, 6, 17, 8, 0, 0),
          full: true
        ).collect

        expect(github.since_values.first).to be == Time.utc(2026, 5, 3, 8, 0, 0)
        expect(data['targets'].first['latest_run']['run_id']).to be == 2
        expect(data['targets'].first['versions'].length).to be == 1
      end
    end
  end
end
