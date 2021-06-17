RSpec.describe 'Traffic Light Controller' do  
  include CommandHelpers
  include StatusHelpers

  describe "Signal Groups" do
  	
  	# Verify status S0017 number of signal groups
  	#
  	# 1. Given the site is connected
  	# 2. Request status
  	# 3. Expect status response before timeout
  	it 'S0017 number of signal groups', sxl: '>=1.0.7' do |example|
  	  request_status_and_confirm "number of signal groups",
  	    { S0017: [:number] }
  	end
	
  	# 1. Verify connection
  	# 2. Send control command to start signalgrup, set_signal_start= true, include security_code
  	# 3. Wait for status = true  
  	it 'M0010 start signal group', :important, sxl: '>=1.0.8' do |example|
  	  Validator::Site.connected do |task,supervisor,site|
  	    prepare task, site
  	    set_signal_start 'True'
  	  end
  	end

  	# 1. Verify connection
  	# 2. Send control command to stop signalgrup, set_signal_start= false, include security_code
  	# 3. Wait for status = true  
  	it 'M0011 stop signal group', :important, sxl: '>=1.0.8' do |example|
  	  Validator::Site.connected do |task,supervisor,site|
  	    prepare task, site
  	    set_signal_stop 'True'
  	  end
  	end

  	# 1. Verify connection
  	# 2. Send control command to start or stop a  serie of signalgroups
  	# 3. Wait for status = true  
  	it 'M0012 request start/stop of a series of signal groups', :important, sxl: '>=1.0.8' do |example|
  	  Validator::Site.connected do |task,supervisor,site|
  	    prepare task, site
  	    set_signal_start_or_stop '5,4134,65;5,11'
  	  end
  	end

  end
end