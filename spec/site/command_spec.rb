# Test command requests by sending commands and checking 
# responses and status updates

RSpec.describe 'RSMP site commands' do  
  it 'M0001 set yellow flash' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_yellow_flash
      #switch_normal_control
    end
  end

  it 'M0001 set dark mode' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_dark_mode
      switch_normal_control
    end
  end

  it 'M0002 set time plan' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      SITE_CONFIG['plans'].each { |plan| switch_plan plan }
    end
  end

  it 'M0003 set traffic situation' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      SITE_CONFIG['traffic_situations'].each { |ts| switch_traffic_situation ts.to_s }
    end
  end

  it 'M0004 restart' do |example|
    TestSite.log_test_header example
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

  it 'M0005 activate emergency route' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      SITE_CONFIG['emergency_routes'].each { |route| switch_emergency_route route.to_s }
    end
  end

  it 'M0006 activate input' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      unsubscribe_from_all
      switch_input
    end
  end

  it 'M0007 set fixed time' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_fixed_time 'True'
      switch_fixed_time 'False'
    end
  end

  it 'M0008 activate detector logic' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_detector_logic
    end
  end
end
