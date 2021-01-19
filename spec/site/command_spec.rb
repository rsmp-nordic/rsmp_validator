# Test command requests by sending commands and checking 
# responses and status updates

RSpec.describe 'RSMP site commands' do  
  include CommandHelpers
  include StatusHelpers

  it 'M0001 set yellow flash', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_yellow_flash
      switch_normal_control
    end
  end

  it 'M0001 set dark mode', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_dark_mode
      switch_normal_control
    end
  end

  it 'M0002 set time plan', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      SITE_CONFIG['plans'].each { |plan| switch_plan plan }
    end
  end

  it 'M0003 set traffic situation', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      SITE_CONFIG['traffic_situations'].each { |ts| switch_traffic_situation ts.to_s }
    end
  end

  it 'M0004 restart', sxl: '>=1.0.7' do |example|
    TestSite.isolated do |task,supervisor,site|
      prepare task, site
      #if ask_user site, "Going to restart controller. Press enter when ready or 's' to skip:"
      set_restart
      expect { site.wait_for_state :stopped, RSMP_CONFIG['shutdown_timeout'] }.to_not raise_error
    end
    # NOTE
    # when a remote site closes the connection, our site proxy object will stop.
    # when the site reconnects, a new site proxy object will be created.
    # this means we can't wait for the old site to become ready
    # it also means we need a new TestSite.
    TestSite.isolated do |task,supervisor,site|
      prepare task, site
      expect { site.wait_for_state :ready, RSMP_CONFIG['ready_timeout'] }.to_not raise_error
      wait_normal_control
    end
  end

  it 'M0005 activate emergency route', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      SITE_CONFIG['emergency_routes'].each { |route| switch_emergency_route route.to_s }
    end
  end

  it 'M0006 activate input', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      SITE_CONFIG['inputs'].each { |input| switch_input input }
    end
  end

  it 'M0007 set fixed time', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_fixed_time 'True'
      switch_fixed_time 'False'
    end
  end

  it 'M0008 activate detector logic', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_detector_logic
    end
  end

  it 'M0010 start signal group', :important, sxl: '>=1.0.8' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_signal_start 'True'
    end
  end

  it 'M0011 stop signal group', :important, sxl: '>=1.0.8' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_signal_stop 'True'
    end
  end

  it 'M0012 request start/stop of a series of signal groups', :important, sxl: '>=1.0.8' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_signal_start_or_stop '5,4134,65;5,11'
    end
  end

  it 'M0013 activate a series of inputs', sxl: '>=1.0.8' do |example|
    TestSite.connected do |task,supervisor,site|
      status = "5,4134,65;511"
      prepare task, site
      set_series_of_inputs status
    end
  end
  
  it 'M0014 set command table', sxl: '>=1.0.13' do |example|
    TestSite.connected do |task,supervisor,site|
      plan = "1"
      status = "10,10"
      prepare task, site
      set_dynamic_bands status, plan
    end
  end

  it 'M0015 set offset', sxl: '>=1.0.13' do |example|
    TestSite.connected do |task,supervisor,site|
      plan = 1
      status = 255
      prepare task, site
      set_offset status, plan
    end
  end

  it 'M0016 set week table', sxl: '>=1.0.13' do |example|
    TestSite.connected do |task,supervisor,site|
      status = "0-1,6-2"
      prepare task, site
      set_week_table status
    end
  end

  it 'M0017 set time table', sxl: '>=1.0.13' do |example|
    TestSite.connected do |task,supervisor,site|
      status = "12-1-12-59,1-0-23-12"
      prepare task, site
      set_time_table status
    end
  end

  it 'M0018 set cycle time', sxl: '>=1.0.13' do |example|
    TestSite.connected do |task,supervisor,site|
      status = 5
      plan = 0
      prepare task, site
      set_cycle_time status, plan
    end
  end

  it 'M0019 force input', sxl: '>=1.0.13' do |example|
    TestSite.connected do |task,supervisor,site|
      status = 'False'
      input = 1
      inputValue = 'True'
      prepare task, site
      force_input status, input, inputValue
    end
  end

  it 'M0020 force output', sxl: '>=1.0.15' do |example|
    TestSite.connected do |task,supervisor,site|
      status = 'False'
      output = 1
      outputValue = 'True'
      prepare task, site
      force_output status, output, outputValue
    end
  end

  it 'M0021 set trigger sensitivity', sxl: '>=1.0.15' do |example|
    TestSite.connected do |task,supervisor,site|
      status = 'False'
      output = 1
      outputValue = 'True'
      prepare task, site
      set_trigger_level status
    end
  end

  it 'M0103 set security code', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_security_code 1
      set_security_code 2
    end
  end

  it 'M0104 set date', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_date
    end
  end

  it 'Send the wrong security code', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      wrong_security_code 
    end
  end
end
