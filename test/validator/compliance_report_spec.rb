require 'json'
require 'tmpdir'
require 'sus'
require_relative '../../lib/rsmp/validator/compliance/report'

describe RSMP::Validator::Compliance::Report do
  def assertions_with_failure
    assertions = Sus::Assertions.default(output: Sus::Output::Null.new)
    assertions.assert(false, 'expected this to fail')
    assertions
  end

  def config_path(dir)
    path = File.join(dir, 'site.yaml')
    File.write(path, <<~YAML)
      compliance:
        id: cross-rs4s
        kind: site
        name: Cross RS4S/RS4T/RS5
        product_url: https://www.cross-traffic.com/en/traffic-light-controllers/
      sxls:
        tlc: '1.2.1'
    YAML
    path
  end

  def resolved_config(core: '3.2.2', sxls: { 'tlc' => '1.2.1' })
    {
      'core_version' => core,
      'sxls' => sxls.map { |name, version| { 'name' => name, 'version' => version } }
    }
  end

  it 'writes config target metadata and failed status' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'report.json')
      config = config_path(dir)
      RSMP::Validator::Compliance::Report.write(
        path,
        assertions: assertions_with_failure,
        env: {
          'GITHUB_WORKFLOW' => 'Cross RS4S',
          'GITHUB_WORKFLOW_REF' => 'rsmp-nordic/rsmp_validator/.github/workflows/cross_rs4s.yaml@refs/heads/main',
          'GITHUB_EVENT_NAME' => 'schedule',
          'GITHUB_REPOSITORY' => 'rsmp-nordic/rsmp_validator',
          'GITHUB_RUN_ID' => '123',
          'GITHUB_RUN_NUMBER' => '45',
          'GITHUB_RUN_ATTEMPT' => '2'
        },
        log_path: 'validator-cross.log',
        report_json_path: 'compliance-cross.json',
        generated_at: Time.utc(2026, 6, 17, 8, 0, 0),
        config: resolved_config,
        config_path: config
      )

      report = JSON.parse(File.read(path))
      expect(report['target']['id']).to be == 'cross-rs4s'
      expect(report['target']['product_url']).to be == 'https://www.cross-traffic.com/en/traffic-light-controllers/'
      expect(report['workflow']['file']).to be == 'cross_rs4s.yaml'
      expect(report['run']['url']).to be == 'https://github.com/rsmp-nordic/rsmp_validator/actions/runs/123'
      expect(report['run']['log_artifact']).to be == 'validator-cross.log'
      expect(report['run']['report_artifact']).to be == 'compliance-cross.json'
      expect(report['matrix']).to be == { 'core' => '3.2.2', 'sxls' => { 'tlc' => '1.2.1' } }
      expect(report['summary']['status']).to be == 'failed'
      expect(report['summary']['failed_count']).to be == 1
      expect(report['failures'].length).to be == 1
    end
  end

  it 'loads target metadata and matrix values from resolved validator config' do
    assertions = Sus::Assertions.default(output: Sus::Output::Null.new)
    assertions.assert(true)

    report = RSMP::Validator::Compliance::Report.new(
      assertions: assertions,
      env: {},
      generated_at: Time.utc(2026, 6, 17, 8, 0, 0),
      config: resolved_config,
      config_path: 'config/gem_tlc.yaml'
    ).to_h

    expect(report['target']['id']).to be == 'gem-tlc'
    expect(report['target']['name']).to be == 'RSMP Nordic CLI TLC'
    expect(report['matrix']).to be == { 'core' => '3.2.2', 'sxls' => { 'tlc' => '1.2.1' } }
    expect(report['summary']['status']).to be == 'passed'
  end

  it 'reports the SXL version from the resolved matrix config' do
    assertions = Sus::Assertions.default(output: Sus::Output::Null.new)
    assertions.assert(true)

    report = RSMP::Validator::Compliance::Report.new(
      assertions: assertions,
      env: {},
      generated_at: Time.utc(2026, 6, 17, 8, 0, 0),
      config: resolved_config(sxls: { 'tlc' => '1.0.15' })
    ).to_h

    expect(report['matrix']['sxls']).to be == { 'tlc' => '1.0.15' }
  end
end
