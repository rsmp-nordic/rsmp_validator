RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::StatusHelpers
  include Validator::CommandHelpers

  describe "Signal Plan" do
    # Verify status S0014 current time plan
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'currently active is read with S0014', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        if RSMP::Proxy.version_meets_requirement?( site.sxl_version, '>=1.1' )
          status_list = { S0014: [:status,:source] }
        else
          status_list = { S0014: [:status] }
        end
        request_status_and_confirm site, "current time plan", status_list
      end
    end

    # Verify that we change time plan (signal program)
    # We try switching all programs configured
    #
    # 1. Given the site is connected
    # 2. Verify that there is a Validator.config['validator'] with a time plan
    # 3. Send command to switch time plan
    # 4. Wait for status "Current timeplan" = requested time plan
    specify 'currently active is set with M0002', sxl: '>=1.0.7' do |example|
      plans = Validator.config['items']['plans']
      skip("No time plans configured") if plans.nil? || plans.empty?
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        plans.each { |plan| switch_plan plan }
      end
    end

    # Verify status S0018 number of time plans
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'list size is read with S0018', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        request_status_and_confirm site, "number of time plans",
          { S0018: [:number] }
      end
    end

    # Verify status S0022 list of time plans
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'list is read with S0022', sxl: '>=1.0.13' do |example|
      Validator::Site.connected do |task,supervisor,site|
        request_status_and_confirm site, "list of time plans",
          { S0022: [:status] }
      end
    end

    # Verify status S0026 week time table
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'week table is read with S0026', sxl: '>=1.0.13'  do |example|
      Validator::Site.connected do |task,supervisor,site|
        request_status_and_confirm site, "week time table",
          { S0026: [:status] }
      end
    end

    # 1. Verify connection
    # 2. Send control command to set  week_table
    # 3. Wait for status = true  
    specify 'week table is set with M0016', sxl: '>=1.0.13' do |example|
      Validator::Site.connected do |task,supervisor,site|
        status = "0-1,6-2"
        prepare task, site
        set_week_table status
      end
    end

    # Verify status S0027 time tables
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'day table is read with S0027', sxl: '>=1.0.13'  do |example|
      Validator::Site.connected do |task,supervisor,site|
        request_status_and_confirm site, "command table",
          { S0027: [:status] }
      end
    end

    # 1. Verify connection
    # 2. Send control command to set time_table
    # 3. Wait for status = true  
    specify 'day table is set with M0017', sxl: '>=1.0.13' do |example|
      Validator::Site.connected do |task,supervisor,site|
        status = "12-1-12-59,1-0-23-12"
        prepare task, site
        set_day_table status
      end
    end

    # Verify status S0097 version of traffic program
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'version is read with S0097', sxl: '>=1.0.15' do |example|
      Validator::Site.connected do |task,supervisor,site|
        request_status_and_confirm site, "version of traffic program",
          { S0097: [:timestamp,:checksum] }
      end
    end

    # 1. Verify connection
    # 2. Send control command to set cycle time
    # 3. Wait for status = true  
    it 'M0018 set cycle time', sxl: '>=1.0.13' do |example|
      Validator::Site.connected do |task,supervisor,site|
        status = 5
        plan = 0
        prepare task, site
        set_cycle_time status, plan
      end
    end

    # Verify status S0023 command table
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'dynamic bands are read with S0023', sxl: '>=1.0.13' do |example|
      Validator::Site.connected do |task,supervisor,site|
        request_status_and_confirm site, "command table",
          { S0023: [:status] }
      end
    end

    # 1. Verify connection
    # 2. Send control command to set dynamic_bands
    # 3. Wait for status = true
    specify 'dynamic bands are set with M0014', sxl: '>=1.0.13' do |example|
      Validator::Site.connected do |task,supervisor,site|
        plan = "1"
        status = "1-12"
        prepare task, site
        set_dynamic_bands plan, status
      end
    end

    # 1. Given the site is connected
    # 2. Read dynamic band
    # 3. Set dynamic band to 2x previous value
    # 4. Read  band to confirm
    # 5. Set dynamic band to previous value
    # 6. Read dynamic band to confirm

    specify 'dynamic bands values can be changed and read back', sxl: '>=1.0.13' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        plan = 1
        band = 3

        value = get_dynamic_bands(plan, band) || 0
        expect( value ).to be_a(Integer)

        new_value = value + 1
        
        set_dynamic_bands plan, "#{band}-#{new_value}"
        expect( get_dynamic_bands(plan, band) ).to eq(new_value)

        set_dynamic_bands plan, "#{band}-#{value}"
        expect( get_dynamic_bands(plan, band) ).to eq(value)
      end
    end

    # Verify command M0023 timeout of dynamic bands
    #
    # 1. Verify connection
    # 2. Send command to set timeout
    # 3. Wait for status = true
    specify 'timeout for dynamic bands is set with M0023', sxl: '>=1.0.15' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        status = 0
        set_timeout_for_dynamic_bands status
      end
    end

    # Verify status S0024 offset time
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'offset is read with S0024', sxl: '>=1.0.13' do |example|
      Validator::Site.connected do |task,supervisor,site|
        request_status_and_confirm site, "offset time",
          { S0024: [:status] }
      end
    end

    # 1. Verify connection
    # 2. Send control command to set dynamic_bands
    # 3. Wait for status = true  
    specify 'offset is set with M0015', sxl: '>=1.0.13' do |example|
      Validator::Site.connected do |task,supervisor,site|
        plan = 1
        status = 255
        prepare task, site
        set_offset status, plan
      end
    end

    # Verify status S0028 cycle time
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'cycle time is read with S0028', sxl: '>=1.0.13' do |example|
      Validator::Site.connected do |task,supervisor,site|
        request_status_and_confirm site, "cycle time",
          { S0028: [:status] }
      end
    end

    # 1. Verify connection
    # 2. Send control command to set cycle time
    # 3. Wait for status = true  
    specify 'cycle time is set with M0018', sxl: '>=1.0.13' do |example|
      Validator::Site.connected do |task,supervisor,site|
        status = 5
        plan = 0
        prepare task, site
        set_cycle_time status, plan
      end
    end
  end
end
