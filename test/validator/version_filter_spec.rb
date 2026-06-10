require_relative '../../lib/rsmp/validator'

describe Validator::VersionFilter do
  before do
    @old_config = Validator.config
    Validator.config = {
      'core_version' => '3.3.0',
      'sxls' => [
        { 'name' => 'tlc', 'version' => '1.3.0' },
        { 'name' => 'vms', 'version' => '1.5.4' }
      ]
    }
  end

  after do
    Validator.config = @old_config
  end

  it 'matches the primary SXL when no name is given' do
    expect(Validator.sxl_matches?('>=1.3.0')).to be == true
    expect(Validator.sxl_matches?('>=1.4.0')).to be == false
  end

  it 'matches a named SXL' do
    expect(Validator.sxl_matches?('>=1.5.0', name: 'vms')).to be == true
    expect(Validator.sxl_matches?('>=1.5.0', name: 'tlc')).to be == false
  end

  it 'matches the core version' do
    expect(Validator.core_matches?('>=3.3.0')).to be == true
    expect(Validator.core_matches?('<3.3.0')).to be == false
  end
end
