# Test command requests by sending commands and checking 
# responses and status updates

RSpec.describe 'RSMP site commands' do  
  include CommandHelpers
  include StatusHelpers

  # Verify that we can activate yellow flash
  #
  # 1. Given the site is connected
  # 2. Send the control command to switch to Yellow flash
  # 3. Wait for status Yellow flash
  # 4. Send command to switch to normal control
  # 5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"
  it 'M0001 set yellow flash', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_yellow_flash
      switch_normal_control
    end
  end

  # Verify that we can activate dark mode
  #
  # 1. Given the site is connected
  # 2. Send the control command to switch todarkmode
  # 3. Wait for status"Controller on" = false
  # 4. Send command to switch to normal control
  # 5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"
  it 'M0001 set dark mode', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_dark_mode
      switch_normal_control
    end
  end


  # Verify that we change time plan (signal program)
  # We try switching all programs configured
  #
  # 1. Given the site is connected
  # 2. Verify that there is a SITE_CONFIG with a time plan
  # 3. Send command to switch time plan
  # 4. Wait for status "Current timeplan" = requested time plan
  it 'M0002 set time plan', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      plans = SITE_CONFIG['plans']
      cant_test("No time plans configured") if plans.nil? || plans.empty?
      prepare task, site
      plans.each { |plan| switch_plan plan }
    end
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

  # 1. Verify connection i Isolated_mode
  # 2. Send the control command to restart, include security_code
  # 3. Wait for status response= stopped
  # 4. Reconnect as Isolated_mode
  # 5. Wait for status= ready
  # 6. Send command to switch to normal controll
  # 7. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true
  it 'M0004 restart', sxl: '>=1.0.7' do |example|
    TestSite.isolated do |task,supervisor,site|
      prepare task, site
      #if ask_user site, "Going to restart controller. Press enter when ready or 's' to skip:"
      set_restart
      site.wait_for_state :stopped, RSMP_CONFIG['shutdown_timeout']
    end

    # NOTE
    # when a remote site closes the connection, our site proxy object will stop.
    # when the site reconnects, a new site proxy object will be created.
    # this means we can't wait for the old site to become ready
    # it also means we need a new TestSite.
    TestSite.isolated do |task,supervisor,site|
      prepare task, site
      site.wait_for_state :ready, RSMP_CONFIG['ready_timeout']
      wait_normal_control
    end
  end

  # 1. Verify connection
  # 2. Verify that there is a SITE_CONFIG with a  emergency_route
  # 3. Send control command to switch emergency_route
  # 4. Wait for status "emergency_route" = requested  
  it 'M0005 activate emergency route', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      emergency_routes = SITE_CONFIG['emergency_routes']
      cant_test("No emergency routes configured") if emergency_routes.nil? || emergency_routes.empty?
      prepare task, site
      emergency_routes.each { |emergency_route| switch_emergency_route emergency_route.to_s }
    end
  end

  # 1. Verify connection
  # 2. Verify that there is a SITE_CONFIG with a input
  # 3. Send control command to switch input
  # 4. Wait for status "input" = requested  
  it 'M0006 activate input', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      inputs = SITE_CONFIG['inputs']
      cant_test("No inputs configured") if inputs.nil? || inputs.empty?
      prepare task, site
      inputs.each { |input| switch_input input }
    end
  end

  # 1. Verify connection
  # 2. Send the control command to switch to  fixed time= true
  # 3. Wait for status = true
  # 4. Send control command to switch "fixed time"= true
  # 5. Wait for status = false
  it 'M0007 set fixed time', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_fixed_time 'True'
      switch_fixed_time 'False'
    end
  end

  # 1. Verify connection
  # 2. Send control command to switch detector_logic= true
  # 3. Wait for status = true
  it 'M0008 activate detector logic', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_detector_logic
    end
  end

  # 1. Verify connection
  # 2. Send control command to start signalgrup, set_signal_start= true, include security_code
  # 3. Wait for status = true  
  it 'M0010 start signal group', :important, sxl: '>=1.0.8' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_signal_start 'True'
    end
  end

  # 1. Verify connection
  # 2. Send control command to stop signalgrup, set_signal_start= false, include security_code
  # 3. Wait for status = true  
  it 'M0011 stop signal group', :important, sxl: '>=1.0.8' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_signal_stop 'True'
    end
  end

  # 1. Verify connection
  # 2. Send control command to start or stop a  serie of signalgroups
  # 3. Wait for status = true  
  it 'M0012 request start/stop of a series of signal groups', :important, sxl: '>=1.0.8' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_signal_start_or_stop '5,4134,65;5,11'
    end
  end

  # 1. Verify connection
  # 2. Send control command to set a serie of input
  # 3. Wait for status = true  
  it 'M0013 activate a series of inputs', sxl: '>=1.0.8' do |example|
    TestSite.connected do |task,supervisor,site|
      status = "5,4134,65;511"
      prepare task, site
      set_series_of_inputs status
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

  # 1. Verify connection
  # 2. Send control command to set force input
  # 3. Wait for status = true  
  it 'M0019 force input', sxl: '>=1.0.13' do |example|
    TestSite.connected do |task,supervisor,site|
      status = 'False'
      input = 1
      inputValue = 'True'
      prepare task, site
      force_input status, input, inputValue
    end
  end

  # 1. Verify connection
  # 2. Send control command to set force ounput
  # 3. Wait for status = true
  it 'M0020 force output', sxl: '>=1.0.15' do |example|
    TestSite.connected do |task,supervisor,site|
      status = 'False'
      output = 1
      outputValue = 'True'
      prepare task, site
      force_output status, output, outputValue
    end
  end

  # 1. Verify connection
  # 2. Send control command to set trigger level
  # 3. Wait for status = true  
  it 'M0021 set trigger sensitivity', sxl: '>=1.0.15' do |example|
    TestSite.connected do |task,supervisor,site|
      status = 'False'
      output = 1
      outputValue = 'True'
      prepare task, site
      set_trigger_level status
    end
  end

  # 1. Verify connection
  # 2. Send control command to set securitycode_level
  # 3. Wait for status = true
  # 4. Send control command to setsecuritycode_level
  # 5. Wait for status = true
  it 'M0103 set security code', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_security_code 1
      set_security_code 2
    end
  end

  it 'Send the wrong security code', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      wrong_security_code 
    end
  end
end
