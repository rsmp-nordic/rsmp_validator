require_relative '../../lib/rsmp/validator/configuration'

describe RSMP::Validator::Configuration do
  let(:configuration) do
    Object.new.tap do |object|
      object.extend subject
      object.define_singleton_method(:config) { { 'timeouts' => { 'command_response' => 5 } } }
      object.define_singleton_method(:warning) { |message| warnings << message }
      object.define_singleton_method(:warnings) { @warnings ||= [] }
    end
  end

  it 'identifies missing required configuration with its full path' do
    expect do
      configuration.get_config('timeouts', 'priority_completion')
    end.to raise_exception(
      RSMP::Validator::MissingConfiguration,
      message: be == 'Missing required test configuration: timeouts.priority_completion'
    )
  end

  it 'returns configured values' do
    expect(configuration.get_config('timeouts', 'command_response')).to be == 5
  end

  it 'uses an explicit default and warns about the missing setting' do
    expect(configuration.get_config('timeouts', 'priority_completion', default: 10)).to be == 10
    expect(configuration.warnings).to be == [
      'Config ["timeouts", "priority_completion"] not found, using default: 10'
    ]
  end

  it 'uses an assumed value without a warning' do
    expect(configuration.get_config('timeouts', 'priority_completion', assume: 10)).to be == 10
    expect(configuration.warnings).to be == []
  end
end
