require_relative '../../lib/rsmp/validator'

describe 'Validator options' do
  it 'normalizes site-test sxls hash into local supervisor defaults' do
    options = RSMP::Validator::SiteTest::Options.new(
      'sxls' => { 'tlc' => '1.2.1' },
      'local_supervisor' => {}
    )

    expect(options.to_h['sxls']).to be == [{ 'name' => 'tlc', 'version' => '1.2.1' }]
    expect(options.to_h.dig('local_supervisor', 'sites', 'default', 'sxls'))
      .to be == [{ 'name' => 'tlc', 'version' => '1.2.1' }]
  end

  it 'normalizes supervisor-test sxls hash into local site settings' do
    options = RSMP::Validator::SupervisorTest::Options.new(
      'sxls' => { 'tlc' => '1.2.1' },
      'local_site' => {
        'site_id' => 'RN+SI0001',
        'supervisors' => [{ 'ip' => '127.0.0.1', 'port' => 12_111 }]
      }
    )

    expect(options.to_h['sxls']).to be == [{ 'name' => 'tlc', 'version' => '1.2.1' }]
    expect(options.to_h.dig('local_site', 'sxls')).to be == [{ 'name' => 'tlc', 'version' => '1.2.1' }]
  end

  it 'rejects sxls expanded form' do
    expect do
      RSMP::Validator::SiteTest::Options.new(
        'sxls' => { 'tlc' => { 'version' => '1.2.1' } },
        'local_supervisor' => {}
      )
    end.to raise_exception(RSMP::ConfigurationError, message: be == 'sxls/tlc must be a version string')
  end

  it 'converts normalized sxls arrays before passing settings to rsmp nodes' do
    settings = {
      'sxls' => [
        { 'name' => 'tlc', 'version' => '1.3.0' },
        { 'name' => 'vms', 'version' => '1.5.4', 'prefix' => 'vms/' }
      ],
      'sites' => {
        'default' => {
          'sxls' => [
            { 'name' => 'tlc', 'version' => '1.3.0' }
          ]
        }
      }
    }

    normalized = RSMP::Validator::ConfigNormalizer.normalize_supervisor_settings(settings)

    expect(normalized['sxls']).to be == {
      'tlc' => '1.3.0',
      'vms' => '1.5.4'
    }
    expect(normalized.dig('sites', 'default', 'sxls')).to be == { 'tlc' => '1.3.0' }
    expect(settings['sxls']).to be == [
      { 'name' => 'tlc', 'version' => '1.3.0' },
      { 'name' => 'vms', 'version' => '1.5.4', 'prefix' => 'vms/' }
    ]
  end
end
