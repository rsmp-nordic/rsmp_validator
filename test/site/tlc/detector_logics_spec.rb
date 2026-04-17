describe 'Site::Tlc::DetectorLogics' do
  include Validator::Helpers::Status
  include Validator::Helpers::Input

  # Verify status S0016 number of detector logics
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'list size is read with S0016' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      site_proxy.request_status_and_collect({ S0016: [:number] }, within: Validator.get_config('timeouts', 'status_response')).ok!
    end
  end

  # Verify status S0002 detector logic status
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'status is read with S0002' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      site_proxy.request_status_and_collect({ S0002: [:detectorlogicstatus] }, within: Validator.get_config('timeouts', 'status_response')).ok!
    end
  end

  # Verify status S0021 manually set detector logic
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'forcing is read with S0021' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      site_proxy.request_status_and_collect({ S0021: [:detectorlogics] }, within: Validator.get_config('timeouts', 'status_response')).ok!
    end
  end

  # 1. Verify connection
  # 2. Send control command to switch detector_logic= true
  # 3. Wait for status = true
  it 'forcing is set with M0008' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      Validator.get_config('components', 'detector_logic').keys.each_with_index do |component, indx|
        timeout = Validator.get_config('timeouts', 'command_response')
        site_proxy.force_detector_logic(component, status: 'True', mode: 'True', within: timeout)
        wait_for_status(
          site_proxy,
          "detector logic #{component} to be True",
          [{ 'sCI' => 'S0002', 'n' => 'detectorlogicstatus', 's' => /^.{#{indx}}1/ }]
        )

        site_proxy.force_detector_logic(component, status: 'True', mode: 'False', within: timeout)
        wait_for_status(
          site_proxy,
          "detector logic #{component} to be False",
          [{ 'sCI' => 'S0002', 'n' => 'detectorlogicstatus', 's' => /^.{#{indx}}0/ }]
        )
      end
    end
  end

  # Verify status S0031 trigger level sensitivity for loop detector
  #
  # 1. Given the site_proxy is connected
  # 2. Request status
  # 3. Expect status response before timeout
  it 'sensitivity is read with S0031' do
    with_site(:connected, sxl: '>=1.0.15') do |site_proxy|
      site_proxy.request_status_and_collect({ S0031: [:status] }, within: Validator.get_config('timeouts', 'status_response')).ok!
    end
  end
end
