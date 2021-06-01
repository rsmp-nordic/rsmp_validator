RSpec.describe "Traffic Light Controller" do
  include StatusHelpers
  include CommandHelpers

  describe "Signal Plans" do

    # Verify status S0026 week time table
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0026 week time table', sxl: '>=1.0.13'  do |example|
      request_status_and_confirm "week time table",
        { S0026: [:status] }
    end

    # Verify status S0027 time tables
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0027 time tables', sxl: '>=1.0.13'  do |example|
      request_status_and_confirm "command table",
        { S0027: [:status] }
    end

    # Verify that the controller responds to S0001.
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout

    it 'responds to S0001 signal group status', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "signal group status",
        { S0001: [:signalgroupstatus, :cyclecounter, :basecyclecounter, :stage] }
    end

    # Verify status S0014 current time plan
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0014 current time plan', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "current time plan",
        { S0014: [:status] }
    end

    # Verify status S0018 number of time plans
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0018 number of time plans', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "number of time plans",
        { S0018: [:number] }
    end

    # Verify status S0022 list of time plans
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0022 list of time plans', sxl: '>=1.0.13' do |example|
      request_status_and_confirm "list of time plans",
        { S0022: [:status] }
    end

    # Verify status S0097 version of traffic program
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0097 version of traffic program', sxl: '>=1.0.15' do |example|
      request_status_and_confirm "version of traffic program",
        { S0097: [:timestamp,:checksum] }
    end

    # Verify that we change time plan (signal program)
    # We try switching all programs configured
    #
    # 1. Given the site is connected
    # 2. Verify that there is a VALIDATOR_CONFIG with a time plan
    # 3. Send command to switch time plan
    # 4. Wait for status "Current timeplan" = requested time plan
    it 'M0002 set time plan', sxl: '>=1.0.7' do |example|
      TestSite.connected do |task,supervisor,site|
        plans = ITEMS_CONFIG['plans']
        cant_test("No time plans configured") if plans.nil? || plans.empty?
        prepare task, site
        plans.each { |plan| switch_plan plan }
      end
    end

    # 1. Verify connection
    # 2. Send control command to set dynamic_bands
    # 3. Wait for status = true
    it 'M0014 set command table', sxl: '>=1.0.13' do |example|
      TestSite.connected do |task,supervisor,site|
        plan = "1"
        status = "10,10"
        prepare task, site
        set_dynamic_bands status, plan
      end
    end

    # 1. Verify connection
    # 2. Send control command to set dynamic_bands
    # 3. Wait for status = true  
    it 'M0015 set offset', sxl: '>=1.0.13' do |example|
      TestSite.connected do |task,supervisor,site|
        plan = 1
        status = 255
        prepare task, site
        set_offset status, plan
      end
    end

    # 1. Verify connection
    # 2. Send control command to set  week_table
    # 3. Wait for status = true  
    it 'M0016 set week table', sxl: '>=1.0.13' do |example|
      TestSite.connected do |task,supervisor,site|
        status = "0-1,6-2"
        prepare task, site
        set_week_table status
      end
    end

    # 1. Verify connection
    # 2. Send control command to set time_table
    # 3. Wait for status = true  
    it 'M0017 set time table', sxl: '>=1.0.13' do |example|
      TestSite.connected do |task,supervisor,site|
        status = "12-1-12-59,1-0-23-12"
        prepare task, site
        set_time_table status
      end
    end

    # 1. Verify connection
    # 2. Send control command to set cycle time
    # 3. Wait for status = true  
    it 'M0018 set cycle time', sxl: '>=1.0.13' do |example|
      TestSite.connected do |task,supervisor,site|
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
    it 'S0023 command table', sxl: '>=1.0.13' do |example|
      request_status_and_confirm "command table",
        { S0023: [:status] }
    end

    # Verify status S0024 offset time
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0024 offset time', sxl: '>=1.0.13' do |example|
      request_status_and_confirm "offset time",
        { S0024: [:status] }
    end

    # Verify status S0025 time-of-green/time-of-red
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0025 time-of-green/time-of-red', sxl: '>=1.0.13' do |example|
      request_status_and_confirm "time-of-green/time-of-red",
        { S0025: [
            :minToGEstimate,
            :maxToGEstimate,
            :likelyToGEstimate,
            :ToGConfidence,
            :minToREstimate,
            :maxToREstimate,
            :likelyToREstimate
        ] },
        COMPONENT_CONFIG['signal_group'].keys.first
    end

    # Verify status S0028 cycle time
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0028 cycle time', sxl: '>=1.0.13' do |example|
      request_status_and_confirm "cycle time",
        { S0028: [:status] }
    end
  end
end
