RSpec.describe 'Site::Traffic Light Controller' do  
  include Validator::CommandHelpers
  include Validator::StatusHelpers

  describe 'Traffic Situation' do
    # Verify status S0015 current traffic situation
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'is read with S0015', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        if RSMP::Proxy.version_meets_requirement?( site.sxl_version, '>=1.1' )
          status_list = { S0015: [:status,:source] }
        else
          status_list = { S0015: [:status] }
        end
        request_status_and_confirm site, "current traffic situation", status_list
      end
    end

    # Verify that we change traffic situation
    #
    # 1. Given the site is connected
    # 2. Verify that there is a Validator.config['validator'] with a traffic situation
    # 3. Send the control command to switch traffic situation for each traffic situation
    # 4. Wait for status "Current traffic situation" = requested traffic situation
    it 'is set with M0003', sxl: '>=1.0.7' do |example|
      situations = Validator.config['items']['traffic_situations']
      skip("No traffic situations configured") if situations.nil? || situations.empty?
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        situations.each { |traffic_situation| switch_traffic_situation traffic_situation.to_s }
      ensure
        unset_traffic_situation
      end
    end

    # Verify status S0019 number of traffic situations
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'list size is read with S0019', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        request_status_and_confirm site, "number of traffic situations",
          { S0019: [:number] }
      end
    end
  end
end
