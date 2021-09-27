RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::StatusHelpers
  include Validator::CommandHelpers

  describe "Signal Plan" do
    describe 'running' do
      # Verify status S0014 current time plan
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      it 'is read with S0014', sxl: '>=1.0.7' do |example|
        request_status_and_confirm "current time plan",
          { S0014: [:status] }
      end

      # Verify that we change time plan (signal program)
      # We try switching all programs configured
      #
      # 1. Given the site is connected
      # 2. Verify that there is a Validator.config['validator'] with a time plan
      # 3. Send command to switch time plan
      # 4. Wait for status "Current timeplan" = requested time plan
      it 'is set with M0002', sxl: '>=1.0.7' do |example|
        plans = Validator.config['items']['plans']
        skip("No time plans configured") if plans.nil? || plans.empty?
        Validator::Site.connected do |task,supervisor,site|
          prepare task, site
          plans.each { |plan| switch_plan plan }
        end
      end

    end

    describe 'List' do
      # Verify status S0018 number of time plans
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      specify 'size is read with S0018', sxl: '>=1.0.7' do |example|
        request_status_and_confirm "number of time plans",
          { S0018: [:number] }
      end

      # Verify status S0022 list of time plans
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      it 'is read with S0022', sxl: '>=1.0.13' do |example|
        request_status_and_confirm "list of time plans",
          { S0022: [:status] }
      end
    end

    describe 'week table' do
      # Verify status S0026 week time table
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      it 'is read with S0026', sxl: '>=1.0.13'  do |example|
        request_status_and_confirm "week time table",
          { S0026: [:status] }
      end

      # 1. Verify connection
      # 2. Send control command to set  week_table
      # 3. Wait for status = true  
      it 'is set with M0016', sxl: '>=1.0.13' do |example|
        Validator::Site.connected do |task,supervisor,site|
          status = "0-1,6-2"
          prepare task, site
          set_week_table status
        end
      end
    end

    describe 'day table' do
      # Verify status S0027 time tables
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      it 'is read with S0027', sxl: '>=1.0.13'  do |example|
        request_status_and_confirm "command table",
          { S0027: [:status] }
      end

      # 1. Verify connection
      # 2. Send control command to set time_table
      # 3. Wait for status = true  
      it 'is set with M0017', sxl: '>=1.0.13' do |example|
        Validator::Site.connected do |task,supervisor,site|
          status = "12-1-12-59,1-0-23-12"
          prepare task, site
          set_time_table status
        end
      end
    end

    describe 'version' do
      # Verify status S0097 version of traffic program
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      it 'is read with S0097', sxl: '>=1.0.15' do |example|
        request_status_and_confirm "version of traffic program",
          { S0097: [:timestamp,:checksum] }
      end
    end

    describe 'dynamic bands' do
      # Verify status S0023 command table
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      it 'is read with S0023', sxl: '>=1.0.13' do |example|
        request_status_and_confirm "command table",
          { S0023: [:status] }
      end

      # 1. Verify connection
      # 2. Send control command to set dynamic_bands
      # 3. Wait for status = true
      it 'is set with M0014', sxl: '>=1.0.13' do |example|
        Validator::Site.connected do |task,supervisor,site|
          plan = "1"
          status = "10,10"
          prepare task, site
          set_dynamic_bands status, plan
        end
      end
    end

    describe 'offset' do
      # Verify status S0024 offset time
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      it 'is read with S0024', sxl: '>=1.0.13' do |example|
        request_status_and_confirm "offset time",
          { S0024: [:status] }
      end

      # 1. Verify connection
      # 2. Send control command to set dynamic_bands
      # 3. Wait for status = true  
      it 'is set with M0015', sxl: '>=1.0.13' do |example|
        Validator::Site.connected do |task,supervisor,site|
          plan = 1
          status = 255
          prepare task, site
          set_offset status, plan
        end
      end
    end

    describe 'cycle time' do
      # Verify status S0028 cycle time
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      it 'is read with S0028', sxl: '>=1.0.13' do |example|
        request_status_and_confirm "cycle time",
          { S0028: [:status] }
      end

      # 1. Verify connection
      # 2. Send control command to set cycle time
      # 3. Wait for status = true  
      it 'is set with M0018', sxl: '>=1.0.13' do |example|
        Validator::Site.connected do |task,supervisor,site|
          status = 5
          plan = 0
          prepare task, site
          set_cycle_time status, plan
        end
      end
    end
  end
end
