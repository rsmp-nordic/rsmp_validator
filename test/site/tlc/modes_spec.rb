describe 'Site::Tlc::Modes' do
  include Validator::Helpers::Status
  include Validator::Helpers::Commands
  include Validator::Helpers::Startup

  # Verify status S0020 control mode
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'control mode is read with S0020' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status({ S0020: %i[controlmode intersection] }, within: timeout)
    end
  end

  # Verify status S0005 traffic controller starting
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'startup status is read with S0005' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status({ S0005: [:status] }, within: timeout)
    end
  end

  # Verify status S0005 traffic controller starting by intersection
  # statusByIntersection requires core >= 3.2, since it uses the array data type.
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'startup status is read with S0005 by intersection' do
    skip 'requires core >= 3.2' unless Validator.core_matches?('>=3.2')
    with_site(:connected, sxl: '>=1.2') do |site_proxy|
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status({ S0005: [:statusByIntersection] }, within: timeout)
    end
  end

  # Verify status S0007 controller switched on (dark mode=off)
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'switched on is read with S0007' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status({ S0007: %i[status intersection] }, within: timeout)
    end
  end

  # Verify status S0007 controller switched on, source attribute
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'switched on is read with S0007 with source' do
    with_site(:connected, sxl: '>=1.1') do |site_proxy|
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status({ S0007: %i[status intersection source] }, within: timeout)
    end
  end

  # Verify status S0008 manual control
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'manual control is read with S0008' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      status_list = if RSMP::Proxy.version_meets_requirement?(site_proxy.sxl_version, '>=1.1')
                      { S0008: %i[status intersection source] }
                    else
                      { S0008: %i[status intersection] }
                    end
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status(status_list, within: timeout)
    end
  end

  # Verify status S0009 fixed time control
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'fixed time control is read with S0009' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      status_list = if RSMP::Proxy.version_meets_requirement?(site_proxy.sxl_version, '>=1.1')
                      { S0009: %i[status intersection source] }
                    else
                      { S0009: %i[status intersection] }
                    end
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status(status_list, within: timeout)
    end
  end

  # Verify command M0007 fixed time control
  #
  # 1. Verify connection
  # 2. Send command to switch to fixed time = true
  # 3. Wait for status = true
  # 4. Send command to switch to fixed time = false
  # 5. Wait for status = false
  it 'fixed time control can be activated with M0007' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      timeout = Validator.get_config('timeouts', 'command')
      site_proxy.set_fixed_time('True', within: timeout)
      site_proxy.set_fixed_time('False', within: timeout)
    end
  end

  # Verify status S0010 isolated control
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'isolated control is read with S0010' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      status_list = if RSMP::Proxy.version_meets_requirement?(site_proxy.sxl_version, '>=1.1')
                      { S0010: %i[status intersection source] }
                    else
                      { S0010: %i[status intersection] }
                    end
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status(status_list, within: timeout)
    end
  end

  # Verify status S0032 coordinated control
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'coordinated control is read with S0032' do
    with_site(:connected, sxl: '>=1.1') do |site_proxy|
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status({ S0032: %i[status intersection source] }, within: timeout)
    end
  end

  # Verify status S0011 yellow flash
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'yellow flash can be read with S0011' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      status_list = if RSMP::Proxy.version_meets_requirement?(site_proxy.sxl_version, '>=1.1')
                      { S0011: %i[status intersection source] }
                    else
                      { S0011: %i[status intersection] }
                    end
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status(status_list, within: timeout)
    end
  end

  # Verify that we can activate yellow flash
  #
  # 1. Given the site_proxy is connected
  # 2. Send the control command to switch to Yellow flash
  # 3. Wait for status Yellow flash
  # 4. Send command to switch to normal control
  # 5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"
  it 'yellow flash can be activated with M0001' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      yellow_flash_timeout = Validator.get_config('timeouts', 'yellow_flash')
      startup_timeout = Validator.get_config('timeouts', 'startup_sequence')
      site_proxy.set_functional_position('YellowFlash', within: yellow_flash_timeout)
      site_proxy.set_functional_position('NormalControl', within: startup_timeout)
    end
  end

  # Verify that we can yellow flash causes all groups to go to state 'c'
  #
  # 1. Given the site_proxy is connected
  # 2. Send the control command to switch to Yellow flash
  # 3. Wait for all groups to go to group 'c'
  # 4. Send command to switch to normal control
  # 5. Wait for all groups to switch do something else that 'c'
  it 'yellow flash affects all signal groups' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      timeout = Validator.get_config('timeouts', 'yellow_flash')

      site_proxy.set_functional_position('YellowFlash', within: timeout)
      site_proxy.wait_for_groups 'c', timeout: timeout      # c means yellow flash

      startup_timeout = Validator.get_config('timeouts', 'startup_sequence')
      site_proxy.set_functional_position('NormalControl', within: startup_timeout)
      site_proxy.wait_for_groups '[^c]', timeout: timeout   # not c, ie. not yellow flash
    end
  end

  # Verify status S0012 all red
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'all red can be read with S0012' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      status_list = if RSMP::Proxy.version_meets_requirement?(site_proxy.sxl_version, '>=1.1')
                      { S0012: %i[status intersection source] }
                    else
                      { S0012: %i[status intersection] }
                    end
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status(status_list, within: timeout)
    end
  end

  # Verify status S0013 police key
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'police key can be read with S0013' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status({ S0013: [:status] }, within: timeout)
    end
  end

  # Verify that we can activate dark mode
  #
  # 1. Given the site_proxy is connected
  # 2. Send the control command to switch todarkmode
  # 3. Wait for status"Controller on" = false
  # 4. Send command to switch to normal control
  # 5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"
  it 'dark mode can be activated with M0001' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      timeout = Validator.get_config('timeouts', 'functional_position')
      startup_timeout = Validator.get_config('timeouts', 'startup_sequence')
      site_proxy.set_functional_position('Dark', within: timeout)
      site_proxy.set_functional_position('NormalControl', within: startup_timeout)
    end
  end

  # Verify that we can activate yellow flash and after 1 minute goes back to NormalControl
  #
  # 1. Given the site_proxy is connected
  # 2. Send the control command to switch to Normal Control, and wait for this
  # 2. Send the control command to switch to Yellow flash
  # 3. Wait for status Yellow flash
  # 5. Wait for automatic revert to Normal Control
  it 'can use yellow flash with a timeout of one minute' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      startup_timeout = Validator.get_config('timeouts', 'startup_sequence')
      site_proxy.set_functional_position('NormalControl', within: startup_timeout)
      minutes = 1
      timeout = Validator.get_config('timeouts', 'yellow_flash')
      site_proxy.set_functional_position('YellowFlash', timeout_minutes: minutes, within: timeout)
      fp_timeout = Validator.get_config('timeouts', 'functional_position')
      wait_normal_control(site_proxy, timeout: (minutes * 60) + fp_timeout)
    end
  end
end
