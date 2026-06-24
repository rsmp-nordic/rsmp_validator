require 'stringio'
require_relative '../../lib/rsmp/validator/cli/entrypoint'

ValidatorCliResult = Struct.new(:status, :output, :error, keyword_init: true)

describe 'Validator CLI' do
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

    ValidatorCliResult.new(status: status, output: stdout.string, error: stderr.string)
  end

  it 'shows run and config commands in help' do
    result = invoke_cli('help')

    expect(result.status).to be(:zero?)
    expect(result.output).to be(:include?, 'run PATH')
    expect(result.output).to be(:include?, 'config COMMAND')
  end

  it 'rejects ambiguous log destinations' do
    result = invoke_cli('run', 'test/validator/options_spec.rb', '--log', '--log-path', 'tmp/rsmp.log')

    expect(result.status).to be == 1
    expect(result.error).to be(:include?, '--log and --log-path cannot be used together')
  end

  it 'requires the run command before test paths' do
    result = invoke_cli('test/validator/options_spec.rb')

    expect(result.status).to be == 1
    expect(result.error).to be(:include?, 'Could not find command')
  end
end
