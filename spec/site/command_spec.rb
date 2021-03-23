# Test command requests by sending commands and checking 
# responses and status updates

RSpec.describe 'RSMP site commands' do  
  include CommandHelpers
  include StatusHelpers

  # Verify that we can activate normal control
  #
  # 1. Given the site is connected
  # 2. When the command to switch to normal control is sent
  # 3. Then the statuses is expected to be "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"
  it 'M0001 set normal control', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_normal_control
    end
  end

  # Verify that we can activate yellow flash
  #
  # 1. Given the site is connected
  # 2. When the command to switch to Yellow flash is sent
  # 3. Then the Yellow flash status is expected to be true
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
  # 2. When the command to switch to dark mode is sent
  # 3. Then the dark mode status is expected to be true
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
  # 1. Given the site is connected and there is a SITE_CONFIG with a time plan
  # 2. When command to switch time plan is sent
  # 3. Then the current timeplan status is expected to be the set timeplan
  it 'M0002 set time plan', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      plans = SITE_CONFIG['plans']
      cant_test("No time plans configured") if plans.nil? || plans.empty?
      prepare task, site
      plans.each { |plan| switch_plan plan }
    end
  end

  # Verify that we change traffic situtation
  # We try switching all traffic situations configured
  #
  # 1. Given the site is connected and there is a SITE_CONFIG with one or more traffic situations
  # 2. When the control command to switch traffic situation is sent
  # 3. Then the current traffic situation status is expected to be the switched to traffic situation
  it 'M0003 set traffic situation', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      situations = SITE_CONFIG['traffic_situations']
      cant_test("No traffic situations configured") if situations.nil? || situations.empty?
      prepare task, site
      situations.each { |traffic_situation| switch_traffic_situation traffic_situation.to_s }
    end
  end

  # Verify that restart command works
  #
  # 1. Given the site is connected
  # 2. When the command to stop the controller is sent
  # 3. Then site stopped is expected
  # 4. When the site is connected and ready again, and a command to set normal control is sent
  # 5. Then the normal control status is expected to be true.
  it 'M0004 restart', sxl: '>=1.0.7' do |example|
    TestSite.isolated do |task,supervisor,site|
      prepare task, site
      # if ask_user site, "Going to restart controller. Press enter when ready or 's' to skip:"
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

  # Verify that switch emergency route command works
  #
  # 1. Given the site is connected and SITE_CONFIG contains an emergency route
  # 2. When command to switch emergency route is sent
  # 3. Then emergency route status is expected to be the set emergency route  
  it 'M0005 activate emergency route', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      emergency_routes = SITE_CONFIG['emergency_routes']
      cant_test("No emergency routes configured") if emergency_routes.nil? || emergency_routes.empty?
      prepare task, site
      emergency_routes.each { |emergency_route| switch_emergency_route emergency_route.to_s }
    end
  end

  # Verify that activate input command works
  #
  # 1. Given the site is connected and SITE_CONFIG contains an input
  # 2. When command to activate input is sent
  # 3. Then input status is expected to be the set input
  it 'M0006 activate input', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      inputs = SITE_CONFIG['inputs']
      cant_test("No inputs configured") if inputs.nil? || inputs.empty?
      prepare task, site
      inputs.each { |input| switch_input input }
    end
  end

  # Verify that set fixed time command works
  #
  # 1. Given the site is connected
  # 2. When the command to switch on fixed time is sent
  # 3. Then the fixed time status is expected to be true
  # 4. When the command to switch off fixed time is sent
  # 5. Then the fixed time status is expected to be false
  it 'M0007 set fixed time', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_fixed_time 'True'
      switch_fixed_time 'False'
    end
  end

  # Verify that activate detector logic command works
  #
  # 1. Given the site is connected
  # 2. When the activate detector logic command is sent
  # 3. Then the activate detector logic status is expected to be true
  it 'M0008 activate detector logic', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_detector_logic
    end
  end

  # Verify that start signal group command works
  #
  # 1. Given the site is connected
  # 2. When the start signal group command is sent
  # 3. Then a command response is expected before timeout
  it 'M0010 start signal group', :important, sxl: '>=1.0.8' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_signal_start 'True'
    end
  end

  # Verify that stop signal group command works
  #
  # 1. Given the site is connected
  # 2. When the stop signal group command is sent
  # 3. Then a command response is expected before timeout
  it 'M0011 stop signal group', :important, sxl: '>=1.0.8' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_signal_stop 'True'
    end
  end

  # Verify that start/stop of a series of signal groups command works
  #
  # 1. Given the site is connected
  # 2. When the start/stop signal groups command is sent
  # 3. Then a command response is expected before timeout
  it 'M0012 request start/stop of a series of signal groups', :important, sxl: '>=1.0.8' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_signal_start_or_stop '5,4134,65;5,11'
    end
  end

  # Verify that activate a series of inputs command works
  #
  # 1. Given the site is connected
  # 2. When command to activate a series of inputs is sent
  # 3. Then a command response is expected before timeout
  it 'M0013 activate a series of inputs', sxl: '>=1.0.8' do |example|
    TestSite.connected do |task,supervisor,site|
      status = "5,4134,65;511"
      prepare task, site
      set_series_of_inputs status
    end
  end

  # Verify that set command table command works
  #
  # 1. Given the site is connected
  # 2. When command to set command table is sent
  # 3. Then a command response is expected before timeout
  it 'M0014 set command table', sxl: '>=1.0.13' do |example|
    TestSite.connected do |task,supervisor,site|
      plan = "1"
      status = "10,10"
      prepare task, site
      set_dynamic_bands status, plan
    end
  end

  # Verify that set offset command works
  #
  # 1. Given the site is connected
  # 2. When command to set offset is sent
  # 3. Then a command response is expected before timeout
  it 'M0015 set offset', sxl: '>=1.0.13' do |example|
    TestSite.connected do |task,supervisor,site|
      plan = 1
      status = 255
      prepare task, site
      set_offset status, plan
    end
  end

  # Verify that set week table command works
  #
  # 1. Given the site is connected
  # 2. When command to set week table is sent
  # 3. Then a command response is expected before timeout
  it 'M0016 set week table', sxl: '>=1.0.13' do |example|
    TestSite.connected do |task,supervisor,site|
      status = "0-1,6-2"
      prepare task, site
      set_week_table status
    end
  end

  # Verify that set time table command works
  #
  # 1. Given the site is connected
  # 2. When command to set time table is sent
  # 3. Then a command response is expected before timeout
  it 'M0017 set time table', sxl: '>=1.0.13' do |example|
    TestSite.connected do |task,supervisor,site|
      status = "12-1-12-59,1-0-23-12"
      prepare task, site
      set_time_table status
    end
  end

  # Verify that set cycle time command works
  #
  # 1. Given the site is connected
  # 2. When command to set cycle time is sent
  # 3. Then a command response is expected before timeout
  it 'M0018 set cycle time', sxl: '>=1.0.13' do |example|
    TestSite.connected do |task,supervisor,site|
      status = 5
      plan = 0
      prepare task, site
      set_cycle_time status, plan
    end
  end

  # Verify that force input command works
  #
  # 1. Given the site is connected
  # 2. When command to force input is sent
  # 3. Then a command response is expected before timeout
  it 'M0019 force input', sxl: '>=1.0.13' do |example|
    TestSite.connected do |task,supervisor,site|
      status = 'False'
      input = 1
      inputValue = 'True'
      prepare task, site
      force_input status, input, inputValue
    end
  end

  # Verify that force output command works
  #
  # 1. Given the site is connected
  # 2. When command to force output is sent
  # 3. Then a command response is expected before timeout
  it 'M0020 force output', sxl: '>=1.0.15' do |example|
    TestSite.connected do |task,supervisor,site|
      status = 'False'
      output = 1
      outputValue = 'True'
      prepare task, site
      force_output status, output, outputValue
    end
  end

  # Verify that set trigger sensitivity command works
  #
  # 1. Given the site is connected
  # 2. When command to set trigger sensitivity is sent
  # 3. Then a command response is expected before timeout
  it 'M0021 set trigger sensitivity', sxl: '>=1.0.15' do |example|
    TestSite.connected do |task,supervisor,site|
      status = 'False'
      output = 1
      outputValue = 'True'
      prepare task, site
      set_trigger_level status
    end
  end

  # Verify that set security code command works
  #
  # 1. Given the site is connected
  # 2. When command to set security code is sent
  # 3. Then a command response is expected before timeout
  it 'M0103 set security code', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_security_code 1
      set_security_code 2
    end
  end

  # Verify that set security code command workswith wrong security codes
  #
  # 1. Given the site is connected
  # 2. When command to set security code is sent
  # 3. Then a command response is expected before timeout
  it 'Send the wrong security code', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      wrong_security_code 
    end
  end
end
