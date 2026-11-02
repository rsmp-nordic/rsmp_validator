require 'stringio'
require 'tmpdir'
require_relative '../../lib/rsmp/validator'
require_relative '../../lib/rsmp/validator/cli/entrypoint'

VALIDATOR_CONFIG_DIR = File.expand_path('../../config', __dir__)
DEVICE_CONFIG_PATHS = Dir[File.join(VALIDATOR_CONFIG_DIR, '{sites,supervisors}', '**', '*.{yaml,yml}')].reject do |path|
  path.end_with?('_secrets.yaml', '_secrets.yml')
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
    path = File.join(VALIDATOR_CONFIG_DIR, 'sites/gem_tlc.yaml')
    result = invoke_cli('config', 'check', path)

    expect(result.status).to be(:zero?)
    expect(result.output).to be == "OK: #{path}\n"
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
      expect(result.output).to be(:include?, "Error: #{path}: Invalid configuration")
      expect(result.output).to be(:include?, '/default')
    end
  end

  it 'reports configs whose mode cannot be inferred' do
    result = invoke_cli('config', 'check', File.join(VALIDATOR_CONFIG_DIR, 'simulator/tlc.yaml'))

    expect(result.status).to be == 1
    expect(result.output).to be(:include?, 'Cannot infer validator config mode')
  end

  it 'reports empty directories' do
    Dir.mktmpdir('rsmp-validator-config') do |dir|
      result = invoke_cli('config', 'check', dir)

      expect(result.status).to be == 1
      expect(result.output).to be(:include?, "Error: #{dir}: No test config files found")
    end
  end

  it 'reports non-yaml files' do
    with_temp_config('site.json', '{"local_supervisor":{}}') do |path|
      result = invoke_cli('config', 'check', path)

      expect(result.status).to be == 1
      expect(result.output).to be(:include?, "Error: #{path}: must be a YAML file")
    end
  end

  it 'checks all site and supervisor directories in one invocation' do
    result = invoke_cli('config', 'check', File.join(VALIDATOR_CONFIG_DIR, 'sites'),
                        File.join(VALIDATOR_CONFIG_DIR, 'supervisors'))

    expect(result.status).to be(:zero?)
    expect(result.output.lines).to be == DEVICE_CONFIG_PATHS.map { |path| "OK: #{path}\n" }
    expect(DEVICE_CONFIG_PATHS).not.to be(:empty?)
  end

  it 'recurses into directories and skips sidecars and non-YAML files' do
    settings = YAML.load_file(File.join(VALIDATOR_CONFIG_DIR, 'sites/gem_tlc.yaml'))
    settings.delete('compliance')
    secrets = settings.delete('secrets')
    Dir.mktmpdir('rsmp-validator-config') do |dir|
      nested = File.join(dir, 'nested')
      Dir.mkdir(nested)
      path = File.join(nested, 'site.yml')
      File.write(path, YAML.dump(settings))
      File.write(File.join(nested, 'site_secrets.yaml'), YAML.dump(secrets))
      File.write(File.join(nested, 'unused_secrets.yml'), 'not a test config')
      File.write(File.join(dir, 'README.txt'), 'not a test config')

      result = invoke_cli('config', 'check', dir)

      expect(result.status).to be(:zero?)
      expect(result.output).to be == "OK: #{path}\n"
    end
  end

  it 'reports malformed YAML and continues checking other files and paths' do
    valid_path = File.join(VALIDATOR_CONFIG_DIR, 'sites/gem_tlc.yaml')
    with_temp_config('a-invalid.yaml', '{') do |path|
      dir = File.dirname(path)
      next_path = File.join(dir, 'z-valid.yaml')
      File.write(next_path, File.read(valid_path))

      result = invoke_cli('config', 'check', dir, valid_path)

      expect(result.status).to be == 1
      expect(result.output).to be(:include?, "Error: #{path}: Cannot read config file")
      expect(result.output).to be(:include?, "OK: #{next_path}\n")
      expect(result.output).to be(:include?, "OK: #{valid_path}\n")
    end
  end

  it 'continues after an empty directory or a missing path' do
    valid_path = File.join(VALIDATOR_CONFIG_DIR, 'sites/gem_tlc.yaml')
    Dir.mktmpdir('rsmp-validator-config') do |dir|
      missing_path = File.join(dir, 'missing.yaml')
      result = invoke_cli('config', 'check', dir, missing_path, valid_path)

      expect(result.status).to be == 1
      expect(result.output).to be(:include?, "Error: #{dir}: No test config files found")
      expect(result.output).to be(:include?, "Error: #{missing_path}: not found")
      expect(result.output).to be(:include?, "OK: #{valid_path}\n")
    end
  end

  it 'applies version overrides to directory checks' do
    settings = YAML.load_file(File.join(VALIDATOR_CONFIG_DIR, 'sites/gem_tlc.yaml'))
    settings['timeouts'].delete('priority_completion')
    with_temp_config('site.yaml', YAML.dump(settings)) do |path|
      dir = File.dirname(path)
      older = invoke_cli('config', 'check', dir, '--core', '3.1.5', '--sxls', 'tlc:1.0.15')
      newer = invoke_cli('config', 'check', dir, '--core', '3.1.5', '--sxls', 'tlc:1.1.0')

      expect(older.status).to be(:zero?)
      expect(newer.status).to be == 1
      expect(newer.output).to be(:include?, 'priority_completion')
    end
  end
end
