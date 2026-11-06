require_relative '../../lib/rsmp/validator'

describe RSMP::Validator::ConfigNormalizer do
  let(:keys) { { '1' => 'valid', "1\nextra" => 'suffix', "extra\n1" => 'prefix', "2\n" => 'newline' } }
  let(:expected) { { 1 => 'valid', "1\nextra" => 'suffix', "extra\n1" => 'prefix', "2\n" => 'newline' } }

  it 'only converts entire numeric security-code keys' do
    settings = { 'security_codes' => keys }
    subject.normalize_security_codes!(settings)

    expect(settings['security_codes']).to be == expected
  end

  it 'only converts entire numeric input-programming keys' do
    expect(subject.normalize_programming_keys(keys)).to be == expected
  end

  it 'preserves the auto-site SXL version list through node construction' do
    versions = ['1.2.1', '1.0.15']
    options = RSMP::Site::Options.new('sxls' => { 'tlc' => versions }).to_h

    normalized = subject.normalize_site_settings(options)
    site = RSMP::Site.new(site_settings: normalized)

    expect(normalized['sxls']).to be == { 'tlc' => versions }
    expect(site.sxls.first['versions']).to be == versions
    expect(site.sxl_version).to be == '1.2.1'
    expect(options['sxls'].first['versions']).to be == versions
  end

  it 'only converts entire numeric keys from secrets' do
    configuration = { 'secrets' => { 'security_codes' => keys } }
    helper = Object.new.extend(RSMP::Validator::Configuration::Secrets)
    helper.define_singleton_method(:config) { configuration }

    helper.send(:normalize_security_codes!)

    expect(configuration['secrets']['security_codes']).to be == expected
  end
end
