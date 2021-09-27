RSpec.describe 'Site::Traffic Light Controller' do  
  include Validator::CommandHelpers
  include Validator::StatusHelpers

  describe 'Traffic Situation' do
    describe 'active' do
      # Verify status S0015 current traffic situation
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      it 'is read with S0015', sxl: '>=1.0.7' do |example|
        request_status_and_confirm "current traffic situation",
          { S0015: [:status] }
      end

      # Verify that we change traffic situtation
      #
      # 1. Given the site is connected
      # 2. Verify that there is a Validator.config['validator'] with a traffic situation
      # 3. Send the control command to switch traffic situation for each traffic situation
      # 4. Wait for status "Current traffic situatuon" = requested traffic situation
      it 'is set with M0003', sxl: '>=1.0.7' do |example|
        situations = Validator.config['items']['traffic_situations']
        skip("No traffic situations configured") if situations.nil? || situations.empty?
        Validator::Site.connected do |task,supervisor,site|
          prepare task, site
          situations.each { |traffic_situation| switch_traffic_situation traffic_situation.to_s }
        end
      end
    end

    describe 'List' do
      # Verify status S0019 number of traffic situations
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      specify 'size is read with S0019', sxl: '>=1.0.7' do |example|
        request_status_and_confirm "number of traffic situations",
          { S0019: [:number] }
      end
    end
  end
end