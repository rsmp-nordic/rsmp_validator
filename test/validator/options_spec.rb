require_relative '../../lib/rsmp/validator'

describe 'Validator options' do
  it 'preserves legacy versions when building site-test defaults' do
    options = RSMP::Validator::SiteTest::Options.new(
      'core_version' => '3.2',
      'sxls' => { 'tlc' => '1.2' },
      'local_supervisor' => {}
    ).to_h

    expect(options['core_version']).to be == '3.2'
    expect(options['sxls']).to be == [{ 'name' => 'tlc', 'version' => '1.2' }]
    expect(options.dig('local_supervisor', 'sites', 'default', 'core_version')).to be == '3.2'
    expect(options.dig('local_supervisor', 'sites', 'default', 'sxls'))
      .to be == [{ 'name' => 'tlc', 'version' => '1.2' }]
  end

  it 'preserves legacy versions when building supervisor-test defaults' do
    options = RSMP::Validator::SupervisorTest::Options.new(
      'core_version' => '3.2',
      'sxls' => { 'tlc' => '1.2' },
      'local_site' => {
        'site_id' => 'RN+SI0001',
        'supervisors' => [{ 'ip' => '127.0.0.1', 'port' => 12_111 }]
      }
    ).to_h

    expect(options['core_version']).to be == '3.2'
    expect(options['sxls']).to be == [{ 'name' => 'tlc', 'version' => '1.2' }]
    expect(options.dig('local_site', 'core_version')).to be == '3.2'
    expect(options.dig('local_site', 'sxls')).to be == [{ 'name' => 'tlc', 'version' => '1.2' }]
  end

  it 'canonicalizes validator metadata without changing embedded node versions' do
    old_config = RSMP::Validator.config
    options = RSMP::Validator::SupervisorTest::Options.new(
      'core_version' => '3.2',
      'sxls' => { 'tlc' => '1.2' },
      'local_site' => {
        'core_version' => '3.2',
        'sxls' => { 'tlc' => '1.1' },
        'site_id' => 'RN+SI0001',
        'supervisors' => [{ 'ip' => '127.0.0.1', 'port' => 12_111 }]
      }
    ).to_h
    RSMP::Validator.config = options

    RSMP::Validator.send(:normalize_core_version!)
    RSMP::Validator.send(:normalize_sxls!)

    expect(options['core_version']).to be == '3.2.0'
    expect(options['sxls']).to be == [{ 'name' => 'tlc', 'version' => '1.2.0' }]
    expect(options.dig('local_site', 'core_version')).to be == '3.2'
    expect(options.dig('local_site', 'sxls')).to be == [{ 'name' => 'tlc', 'version' => '1.1' }]
  ensure
    RSMP::Validator.config = old_config
  end

  it 'places auto-supervisor SXL overrides in the default site settings' do
    old_mode = RSMP::Validator.mode
    old_override = RSMP::Validator.sxls_override
    RSMP::Validator.mode = :supervisor
    RSMP::Validator.sxls_override = 'tlc:1.2'
    raw = { 'sites' => { 'default' => {} } }

    RSMP::Validator.send(:apply_auto_node_overrides!, raw)

    expect(raw.key?('sxls')).to be == false
    expect(raw.dig('sites', 'default', 'sxls')).to be == { 'tlc' => '1.2' }
  ensure
    RSMP::Validator.mode = old_mode
    RSMP::Validator.sxls_override = old_override
  end

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

  it 'keeps collector options out of embedded rsmp node settings' do
    tester = RSMP::Validator::SiteTester.allocate
    node_options = tester.send(:rsmp_node_options, 'collect' => { 'timeout' => 1 }, 'core_version' => '3.3.0')

    expect(node_options).to be == { 'core_version' => '3.3.0' }
  end
end
