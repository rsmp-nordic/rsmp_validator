require 'stringio'
require 'tmpdir'
require 'open3'
require_relative '../../lib/rsmp/validator'
require_relative '../../lib/rsmp/validator/cli/entrypoint'

describe 'Versioned test configuration schemas' do
  let(:raw) { YAML.load_file(File.expand_path('../../config/sites/gem_tlc.yaml', __dir__)) }

  def check(settings = raw, **overrides)
    RSMP::Validator::ConfigCheck.build_options(settings, mode: :site, path: nil, **overrides).to_h
  end

  def invoke_check(path, *args)
    output = StringIO.new
    previous_stdout = $stdout
    $stdout = output
    status = 0
    begin
      RSMP::Validator::CLI.start(['config', 'check', path, *args])
    rescue SystemExit => e
      status = e.status
    ensure
      $stdout = previous_stdout
    end
    [status, output.string]
  end

  it 'requires priority completion from TLC 1.1.0 regardless of Core version' do
    raw['timeouts'].delete('priority_completion')

    expect do
      check(core: '3.1.5', sxls: 'tlc:1.1.0')
    end.to raise_exception(RSMP::ConfigurationError, message: be(:include?, 'priority_completion'))
  end

  it 'ignores unused settings including their types for older TLC versions' do
    raw['timeouts']['priority_completion'] = 'unused'
    raw['items']['outputs'] = { 'unused' => true }
    raw['future_setting'] = true

    expect(check(sxls: 'tlc:1.0.14').dig('timeouts', 'priority_completion')).to be == 'unused'
  end

  it 'requires output items from TLC 1.0.15' do
    raw['items'].delete('outputs')

    expect(check(sxls: 'tlc:1.0.14')['sxls'].first['version']).to be == '1.0.14'
    expect do
      check(sxls: 'tlc:1.0.15')
    end.to raise_exception(RSMP::ConfigurationError, message: be(:include?, 'outputs'))
  end

  ['5', 0, -1, nil].each do |value|
    it "rejects invalid active timeout #{value.inspect}" do
      raw['timeouts']['priority_completion'] = value

      expect do
        check
      end.to raise_exception(RSMP::ConfigurationError, message: be(:include?, '/timeouts/priority_completion'))
    end
  end

  it 'validates fractional timeouts' do
    raw['timeouts']['priority_completion'] = 0.5
    expect(check.dig('timeouts', 'priority_completion')).to be_a(Float)
  end

  it 'requires Core settings independently of the SXL' do
    raw['sxls'] = {}
    raw['timeouts'].delete('ready')

    expect do
      check
    end.to raise_exception(RSMP::ConfigurationError, message: be(:include?, 'ready'))
  end

  it 'does not require TLC settings for Core-only testing' do
    raw['sxls'] = {}
    %w[items startup_sequence secrets alarm_triggers].each { |key| raw[key] = 'unused' }
    raw['timeouts'].delete('priority_completion')

    checked = check
    expect(checked['sxls']).to be == []
    tester = RSMP::Validator::SiteTester.allocate
    tester.define_singleton_method(:config) { checked }
    tester.parse_config
  end

  it 'selects Core requirements independently for Core-only configurations' do
    raw['sxls'] = {}
    raw['timeouts'].delete('status_update')
    raw['timeouts'].delete('status_response')

    expect(check(core: '3.1.3')['core_version']).to be == '3.1.3'
    expect do
      check(core: '3.1.4')
    end.to raise_exception(RSMP::ConfigurationError, message: be(:include?, 'status_update'))

    raw['timeouts']['status_update'] = 1
    expect(check(core: '3.1.4')['core_version']).to be == '3.1.4'
    expect do
      check(core: '3.1.5')
    end.to raise_exception(RSMP::ConfigurationError, message: be(:include?, 'status_response'))
  end

  it 'rejects empty required component and item lists' do
    raw['components']['main'] = {}
    expect do
      check
    end.to raise_exception(RSMP::ConfigurationError, message: be(:include?, '/components/main'))

    raw['components']['main'] = { 'TC' => nil }
    raw['items']['plans'] = []
    expect do
      check
    end.to raise_exception(RSMP::ConfigurationError, message: be(:include?, '/items/plans'))
  end

  it 'preserves explicit optional alarm triggers and emergency routes' do
    raw.delete('alarm_triggers')
    raw['items']['emergency_routes'] = []

    expect(check.dig('items', 'emergency_routes')).to be == []
  end

  it 'uses canonical SXL versions and preserves embedded legacy Core versions' do
    checked = check(core: '3.2', sxls: 'tlc:1.2.0')

    expect(checked['core_version']).to be == '3.2.0'
    expect(checked['sxls']).to be == [{ 'name' => 'tlc', 'version' => '1.2.0' }]
    expect(checked.dig('local_supervisor', 'sites', 'default', 'core_version')).to be == '3.2'
    expect(checked.dig('local_supervisor', 'sites', 'default', 'sxls').first['version']).to be == '1.2.0'
    expect(raw['sxls']).to be == { 'tlc' => '1.2.1' }
  end

  it 'resolves latest versions before choosing schemas' do
    checked = check(core: 'latest', sxls: 'tlc:latest')

    expect(checked['core_version']).to be == RSMP::Schema.latest_core_version
    expect(checked['sxls'].first['version']).to be == RSMP::Schema.latest_version(:tlc)
  end

  it 'rejects legacy SXL spellings in config and CLI overrides' do
    expect { check(sxls: 'tlc:1.2') }.to raise_exception(RSMP::ConfigurationError)

    raw['sxls'] = { 'tlc' => '1.2' }
    expect { check }.to raise_exception(RSMP::ConfigurationError)
  end

  it 'supports all bundled Core and TLC versions' do
    RSMP::Schema.core_versions.each do |version|
      expect(check(core: version)['core_version']).to be == version
    end
    RSMP::Schema.find_schemas!(:tlc).each_key do |version|
      expect(check(sxls: "tlc:#{version}")['sxls'].first['version']).to be == version
    end
  end

  it 'reports invalid and unsupported versions as configuration errors' do
    ['invalid', '99.0.0'].each do |version|
      expect { check(core: version) }.to raise_exception(RSMP::ConfigurationError)
      expect { check(sxls: "tlc:#{version}") }.to raise_exception(RSMP::ConfigurationError)
    end
  end

  it 'rejects malformed SXL overrides' do
    ['', 'tlc', ':1.2.1', 'tlc:', 'tlc:1.2.1,'].each do |override|
      expect { check(sxls: override) }.to raise_exception(RSMP::ConfigurationError)
    end
  end

  it 'checks CLI overrides without changing the file or global validator state' do
    raw['timeouts'].delete('priority_completion')
    old_config = RSMP::Validator.config
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'site.yaml')
      contents = YAML.dump(raw)
      File.write(path, contents)

      status, output = invoke_check(path, '--core', '3.1.5', '--sxls', 'tlc:1.0.15')
      expect(status).to be(:zero?)
      expect(output).to be == "OK: #{path}\n"

      status, output = invoke_check(path, '--core', '3.1.5', '--sxls', 'tlc:1.1.0')
      expect(status).to be == 1
      expect(output).to be(:include?, 'priority_completion')
      expect(File.read(path)).to be == contents
    end
    expect(RSMP::Validator.config).to be(:equal?, old_config)
  end

  it 'loads required security codes from a sidecar file for checks' do
    secrets = raw.delete('secrets')
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'site.yml')
      File.write(path, YAML.dump(raw))
      File.write(File.join(dir, 'site_secrets.yaml'), YAML.dump(secrets))

      checked = RSMP::Validator::ConfigCheck.check_file(path).options.to_h
      expect(checked.dig('secrets', 'security_codes', 1)).to be == '1111'
    end
  end

  it 'reports missing security codes before running tests' do
    raw.delete('secrets')
    expect { check }.to raise_exception(RSMP::ConfigurationError, message: be(:include?, 'secrets'))
  end

  it 'uses the same schema checks and overrides in the run loader' do
    loader = Object.new
    loader.extend RSMP::Validator::Configuration
    loader.define_singleton_method(:mode) { :site }
    loader.define_singleton_method(:core_version_override) { '3.1.5' }
    loader.define_singleton_method(:sxls_override) { 'tlc:1.1.0' }
    loader.define_singleton_method(:abort_with_error) { |message| raise RSMP::ConfigurationError, message }
    raw['timeouts'].delete('priority_completion')

    expect do
      loader.send(:build_tester_options, raw, nil)
    end.to raise_exception(RSMP::ConfigurationError, message: be(:include?, 'priority_completion'))

    loader.define_singleton_method(:sxls_override) { 'tlc:1.0.15' }
    checked = loader.send(:build_tester_options, raw, nil).to_h
    expect(checked['core_version']).to be == '3.1.5'
    expect(checked['sxls'].first['version']).to be == '1.0.15'
  end

  it 'rejects incomplete configuration cleanly even when running a Core-only subset' do
    raw['timeouts'].delete('priority_completion')
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'site.yaml')
      File.write(path, YAML.dump(raw))
      stdout, stderr, status = Open3.capture3(
        'bundle', 'exec', 'rsmp-validator', 'run',
        File.expand_path('../site/core/disconnect_spec.rb', __dir__),
        '--site-config', path, '--core', '3.1.5', '--sxls', 'tlc:1.1.0'
      )

      expect(status.exitstatus).to be == 1
      expect(stderr).to be(:include?, 'priority_completion')
      expect(stderr).not.to be(:include?, 'NoMethodError')
      expect(stderr).not.to be(:include?, 'UncaughtException')
      expect(stdout).not.to be(:include?, 'Waiting for')
    end
  end

  it 'does not require site-test settings when testing a supervisor' do
    settings = YAML.load_file(File.expand_path('../../config/supervisors/gem_supervisor.yaml', __dir__))
    settings['items'] = 'unused'
    checked = RSMP::Validator::ConfigCheck.build_options(settings, mode: :supervisor, path: nil)

    expect(checked.to_h['items']).to be == 'unused'
  end

  it 'loads the base schemas and rejects malformed top-level settings' do
    raw['local_supervisor'] = 'invalid'

    expect { check }.to raise_exception(RSMP::ConfigurationError, message: be(:include?, '/local_supervisor'))
  end

  it 'accepts a boolean or omitted supervisor test scenario switch' do
    settings = YAML.load_file(File.expand_path('../../config/supervisors/gem_supervisor.yaml', __dir__))
    [true, false].each do |enabled|
      settings['test_scenarios'] = enabled
      checked = RSMP::Validator::ConfigCheck.build_options(settings, mode: :supervisor, path: nil).to_h
      expect(checked['test_scenarios']).to be == enabled
    end
    settings.delete('test_scenarios')
    checked = RSMP::Validator::ConfigCheck.build_options(settings, mode: :supervisor, path: nil).to_h
    expect(checked['test_scenarios']).to be_nil

    settings['test_scenarios'] = ['M0002.set_plan']
    expect do
      RSMP::Validator::ConfigCheck.build_options(settings, mode: :supervisor, path: nil)
    end.to raise_exception(RSMP::ConfigurationError, message: be(:include?, '/test_scenarios'))
  end
end
