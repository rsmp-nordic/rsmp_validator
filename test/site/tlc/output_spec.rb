describe 'Site::Tlc::Output' do
  include Validator::Helpers::Status

  # Tests related to outputs.

  # Verify that  output status can be read with S0004, extended output status
  # 1. Given the site is connected
  # 2. When we subscribe to S0004
  # 3. We should receive a status updated
  # 4. And the outputstatus attribute should be a digit string
  it 'is read with S0004 with extended output status' do
    with_site(:connected, sxl: ['>=1.0.7', '<1.2']) do |site_proxy|
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status({ S0004: %i[outputstatus extendedoutputstatus] }, within: timeout)
    end
  end

  # Verify that  output status can be read with S0004
  # 1. Given the site is connected
  # 2. When we subscribe to S0004
  # 3. We should receive a status updated
  # 4. And the outputstatus attribute should be a digit string
  it 'is read with S0004' do
    with_site(:connected, sxl: ['>=1.2']) do |site_proxy|
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status({ S0004: [:outputstatus] }, within: timeout)
    end
  end

  # Verify that forced output status can be read with S0030
  # 1. Given the site is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'forcing is read with S0030' do
    with_site(:connected, sxl: '>=1.0.15') do |site_proxy|
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status({ S0030: [:status] }, within: timeout)
    end
  end

  # Verify that output can be forced with M0020
  # 1. Given the site is connected
  # 2. When we force output with M0020
  # 3. Wait for status = true
  it 'forcing is set with M0020' do
    with_site(:connected, sxl: '>=1.0.15') do |site_proxy|
      outputs = Validator.get_config('items', 'outputs')
      skip('No outputs configured') if outputs.nil? || outputs.empty?
      timeout = Validator.get_config('timeouts', 'command_response')
      outputs.each do |output|
        site_proxy.force_output(output: output, status: 'True', value: 'True', within: timeout)
        site_proxy.force_output(output: output, status: 'True', value: 'False', within: timeout)
      ensure
        site_proxy.force_output(output: output, status: 'False', value: 'True', within: timeout)
      end
    end
  end
end
