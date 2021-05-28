RSpec.describe 'Traffic Light Controller' do  
  include CommandHelpers
  include StatusHelpers

  describe 'Traffic Situations' do

    # Verify status S0015 current traffic situation
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0015 current traffic situation', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "current traffic situation",
        { S0015: [:status] }
    end

    # Verify status S0019 number of traffic situations
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0019 number of traffic situations', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "number of traffic situations",
        { S0019: [:number] }
    end

    # Verify that we change traffic situtation
    #
    # 1. Given the site is connected
    # 2. Verify that there is a SITE_CONFIG with a traffic situation
    # 3. Send the control command to switch traffic situation for each traffic situation
    # 4. Wait for status "Current traffic situatuon" = requested traffic situation
    it 'M0003 set traffic situation', sxl: '>=1.0.7' do |example|
      TestSite.connected do |task,supervisor,site|
        situations = SITE_CONFIG['traffic_situations']
        cant_test("No traffic situations configured") if situations.nil? || situations.empty?
        prepare task, site
        situations.each { |traffic_situation| switch_traffic_situation traffic_situation.to_s }
      end
    end

  end
end