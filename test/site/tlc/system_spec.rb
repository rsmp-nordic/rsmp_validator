describe 'Site::Tlc::System' do
  include Validator::Helpers::Commands
  include Validator::Helpers::Status
  include Validator::Helpers::Security

  # Verify status S0091 operator logged in/out OP-panel
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'operator logged in/out of OP-panel is read with S0091' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      status_list = if RSMP::Proxy.version_meets_requirement?(site_proxy.sxl_version, '>=1.1')
                      { S0091: [:user] }
                    else
                      { S0091: %i[user status] }
                    end
      request_status_and_confirm site_proxy, 'operator logged in/out OP-panel', status_list
    end
  end

  # Verify status S0092 operator logged in/out web-interface
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'operator logged in/out of web-interface is read with S0092' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      status_list = if RSMP::Proxy.version_meets_requirement?(site_proxy.sxl_version, '>=1.1')
                      { S0092: [:user] }
                    else
                      { S0092: %i[user status] }
                    end
      request_status_and_confirm site_proxy, 'operator logged in/out web-interface', status_list
    end
  end

  # Verify status S0095 version of traffic controller
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'version is read with S0095' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      request_status_and_confirm site_proxy, 'version of traffic controller',
                                 { S0095: [:status] }
    end
  end

  # 1. Verify connection
  # 2. Send control command to set securitycode_level
  # 3. Wait for status = true
  # 4. Send control command to setsecuritycode_level
  # 5. Wait for status = true
  it 'security code is set with M0103' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      code1 = Validator.get_config('secrets', 'security_codes', 1)
      code2 = Validator.get_config('secrets', 'security_codes', 2)
      site_proxy.set_security_code(level: 'Level1', old_code: code1, new_code: code1)
      site_proxy.set_security_code(level: 'Level2', old_code: code2, new_code: code2)
    end
  end

  # Verify that the site_proxy responds with NotAck if we send incorrect security cdoes.
  # RThis hehaviour is defined in SXL >= 1.1. For earlier versions,
  # The behaviour is undefined.
  # 1. Given the site_proxy is connected
  # 2. When we send a M0008 command with incorrect security codes
  # 3. Then we should received a NotAck
  it 'security code is rejected when incorrect' do
    with_site(:connected, sxl: '>=1.1') do |site_proxy|
      expect { wrong_security_code(site_proxy) }.to raise_exception(RSMP::MessageRejected)
    end
  end
end
