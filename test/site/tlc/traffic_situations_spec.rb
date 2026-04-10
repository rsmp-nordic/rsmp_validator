describe 'Site::Tlc::TrafficSituations' do
  include Validator::Helpers::Commands
  include Validator::Helpers::Status

  describe 'Traffic Situation' do
    # Verify status S0015 current traffic situation
    #
    # 1. Given the site_proxy is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'is read with S0015' do
      with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
        status_list = if RSMP::Proxy.version_meets_requirement?(site_proxy.sxl_version, '>=1.1')
                        { S0015: %i[status source] }
                      else
                        { S0015: [:status] }
                      end
        request_status_and_confirm site_proxy, 'current traffic situation', status_list
      end
    end

    # Verify that we change traffic situation
    #
    # 1. Given the site_proxy is connected
    # 2. Verify that there is a Validator.get_config('validator') with a traffic situation
    # 3. Send the control command to switch traffic situation for each traffic situation
    # 4. Wait for status "Current traffic situation" = requested traffic situation
    it 'is set with M0003' do
      skip 'requires sxl >= 1.0.7' unless Validator.sxl_matches?('>=1.0.7')
      situations = Validator.get_config('items', 'traffic_situations')
      skip('No traffic situations configured') if situations.nil? || situations.empty?
      with_site(:connected) do |site_proxy|
        situations.each do |traffic_situation|
          site_proxy.set_traffic_situation(traffic_situation.to_s,
                                     options: { confirm!: { timeout: Validator.get_config('timeouts', 'command') } })
        end
      ensure
        site_proxy.unset_traffic_situation
      end
    end

    # Verify status S0019 number of traffic situations
    #
    # 1. Given the site_proxy is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'list size is read with S0019' do
      with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
        request_status_and_confirm site_proxy, 'number of traffic situations',
                                   { S0019: [:number] }
      end
    end
  end
end
