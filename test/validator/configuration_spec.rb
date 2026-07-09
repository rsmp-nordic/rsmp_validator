require_relative '../../lib/rsmp/validator'

describe 'Validator configuration' do
  def configurer(mode:, core: nil, sxls: nil)
    klass = Class.new do
      include RSMP::Validator::Configuration

      attr_accessor :mode, :core_version_override, :sxls_override

      def abort_with_error(message)
        raise message
      end
    end

    instance = klass.new
    instance.mode = mode
    instance.core_version_override = core
    instance.sxls_override = sxls
    instance
  end

  it 'applies CLI overrides to site-test local supervisor site settings' do
    raw_config = {
      'local_supervisor' => {
        'default' => {
          'core_version' => '3.3.0',
          'sxls' => { 'tlc' => '1.2.1' }
        },
        'sites' => {
          'RN+SI0001' => {
            'core_version' => '3.3.0',
            'sxls' => { 'tlc' => '1.2.1' }
          }
        }
      }
    }

    configurer(mode: :site, core: '3.2.2', sxls: 'tlc:1.0.15').apply_cli_overrides!(raw_config)

    expect(raw_config['core_version']).to be == '3.2.2'
    expect(raw_config['sxls']).to be == { 'tlc' => '1.0.15' }
    expect(raw_config.dig('local_supervisor', 'default', 'core_version')).to be == '3.2.2'
    expect(raw_config.dig('local_supervisor', 'default', 'sxls')).to be == { 'tlc' => '1.0.15' }
    expect(raw_config.dig('local_supervisor', 'sites', 'RN+SI0001', 'core_version')).to be == '3.2.2'
    expect(raw_config.dig('local_supervisor', 'sites', 'RN+SI0001', 'sxls')).to be == { 'tlc' => '1.0.15' }
  end

  it 'applies CLI overrides to supervisor-test local site settings' do
    raw_config = {
      'local_site' => {
        'core_version' => '3.3.0',
        'sxls' => { 'tlc' => '1.2.1' }
      }
    }

    configurer(mode: :supervisor, core: '3.2.2', sxls: 'tlc:1.0.15').apply_cli_overrides!(raw_config)

    expect(raw_config['core_version']).to be == '3.2.2'
    expect(raw_config['sxls']).to be == { 'tlc' => '1.0.15' }
    expect(raw_config.dig('local_site', 'core_version')).to be == '3.2.2'
    expect(raw_config.dig('local_site', 'sxls')).to be == { 'tlc' => '1.0.15' }
  end
end
