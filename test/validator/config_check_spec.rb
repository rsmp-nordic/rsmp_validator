require 'stringio'
require 'tmpdir'
require_relative '../../lib/rsmp/validator'
require_relative '../../lib/rsmp/validator/cli/entrypoint'

VALIDATOR_CONFIG_DIR = File.expand_path('../../config', __dir__)
DEVICE_CONFIG_PATHS = Dir[File.join(VALIDATOR_CONFIG_DIR, '*.yaml')].select do |path|
  raw = YAML.load_file(path)
  %w[site supervisor].include?(raw.dig('compliance', 'kind')) if raw.is_a?(Hash)
end
ConfigCheckCliResult = Struct.new(:status, :output, :error, keyword_init: true)

describe 'Validator config check' do
  def invoke_cli(*args)
    stdout = StringIO.new
    stderr = StringIO.new
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = stdout
    $stderr = stderr
    status = 0

    begin
      RSMP::Validator::CLI.start(args.flatten)
    rescue SystemExit => e
      status = e.status
    ensure
      $stdout = old_stdout
      $stderr = old_stderr
    end

    ConfigCheckCliResult.new(status: status, output: stdout.string, error: stderr.string)
  end

  def with_temp_config(name, content)
    Dir.mktmpdir('rsmp-validator-config') do |dir|
      path = File.join(dir, name)
      File.write(path, content)
      yield path
    end
  end

  DEVICE_CONFIG_PATHS.each do |path|
    name = File.basename(path)

    it "validates bundled device config #{name}" do
      result = RSMP::Validator::ConfigCheck.check_file(path)
      expected_mode = YAML.load_file(path).dig('compliance', 'kind')

      expect(result.mode).to be == expected_mode
    end
  end

  it 'validates simulator configs through the rsmp config API' do
    tlc = RSMP::Config.load_file(File.join(VALIDATOR_CONFIG_DIR, 'simulator/tlc.yaml'), type: 'tlc')
    supervisor = RSMP::Config.load_file(File.join(VALIDATOR_CONFIG_DIR, 'simulator/supervisor.yaml'),
                                        type: 'supervisor')

    expect(tlc).to be_a(RSMP::TLC::TrafficControllerSite::Options)
    expect(supervisor).to be_a(RSMP::Supervisor::Options)
  end

  it 'checks validator configs from the CLI' do
    path = File.join(VALIDATOR_CONFIG_DIR, 'gem_tlc.yaml')
    result = invoke_cli('config', 'check', path)

    expect(result.status).to be(:zero?)
    expect(result.output).to be == "OK\n"
  end

  it 'reports embedded RSMP config errors' do
    with_temp_config('bad-site.yaml', <<~YAML) do |path|
      local_supervisor:
        default: invalid
      sxls:
        tlc: '1.2.1'
      timeouts:
        watchdog: 1
      components:
        main:
          TC:
    YAML
      result = invoke_cli('config', 'check', path, '--mode', 'site')

      expect(result.status).to be == 1
      expect(result.output).to be(:include?, 'Error: Invalid configuration')
      expect(result.output).to be(:include?, '/default')
    end
  end

  it 'reports configs whose mode cannot be inferred' do
    result = invoke_cli('config', 'check', File.join(VALIDATOR_CONFIG_DIR, 'simulator/tlc.yaml'))

    expect(result.status).to be == 1
    expect(result.output).to be(:include?, 'Cannot infer validator config mode')
  end

  it 'reports directory paths' do
    Dir.mktmpdir('rsmp-validator-config') do |dir|
      result = invoke_cli('config', 'check', dir)

      expect(result.status).to be == 1
      expect(result.output).to be(:include?, 'Error: is not a file')
    end
  end

  it 'reports non-yaml files' do
    with_temp_config('site.json', '{"local_supervisor":{}}') do |path|
      result = invoke_cli('config', 'check', path)

      expect(result.status).to be == 1
      expect(result.output).to be(:include?, 'Error: must be a YAML file')
    end
  end
end
