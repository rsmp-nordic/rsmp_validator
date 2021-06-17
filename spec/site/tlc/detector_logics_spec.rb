RSpec.describe 'Traffic Light Controller' do  
  include CommandHelpers
  include StatusHelpers

  describe "Detector Logics" do

  	# Verify status S0002 detector logic status
  	#
  	# 1. Given the site is connected
  	# 2. Request status
  	# 3. Expect status response before timeout
  	it 'S0002 detector logic status', sxl: '>=1.0.7' do |example|
  	  request_status_and_confirm "detector logic status",
  	    { S0002: [:detectorlogicstatus] }
  	end

  	# Verify status S0016 number of detector logics
  	#
  	# 1. Given the site is connected
  	# 2. Request status
  	# 3. Expect status response before timeout
  	it 'S0016 number of detector logics', sxl: '>=1.0.7' do |example|
  	  request_status_and_confirm "number of detector logics",
  	    { S0016: [:number] }
  	end

  	# Verify status S0021 manually set detector logic
  	#
  	# 1. Given the site is connected
  	# 2. Request status
  	# 3. Expect status response before timeout
  	it 'S0021 manually set detector logic', sxl: '>=1.0.7' do |example|
  	  request_status_and_confirm "manually set detector logics",
  	    { S0021: [:detectorlogics] }
  	end

  	# Verify status S0031 trigger level sensitivity for loop detector
  	#
  	# 1. Given the site is connected
  	# 2. Request status
  	# 3. Expect status response before timeout
  	it 'S0031 trigger level sensitivity for loop detector', sxl: '>=1.0.15' do |example|
  	  request_status_and_confirm "trigger level sensitivity for loop detector",
  	    { S0031: [:status] }
  	end

  	# 1. Verify connection
  	# 2. Send control command to switch detector_logic= true
  	# 3. Wait for status = true
  	it 'M0008 activate detector logic', sxl: '>=1.0.7' do |example|
  	  Validator::Site.connected do |task,supervisor,site|
  	    prepare task, site
  	    switch_detector_logic
  	  end
  	end

  	it 'A0302 detector error (logic error)', :script, sxl: '>=1.0.7' do |example|
  	  Validator.require_scripts
  	  Validator::Site.connected do |task,supervisor,site|
  	    component = Validator.config['components']['detector_logic'].keys.first
  	    system(Validator.config['scripts']['activate_alarm'])
  	    site.log "Waiting for alarm", level: :test
  	    start_time = Time.now
  	    message, response = nil,nil
  	    expect do
  	      response = site.wait_for_alarm task, component: component, aCId: 'A0302',
  	        aSp: 'Issue', aS: 'Active', timeout: Validator.config['timeouts']['alarm']
  	    end.to_not raise_error, "Did not receive alarm"

  	    delay = Time.now - start_time
  	    site.log "alarm confirmed after #{delay.to_i}s", level: :test
  	    system(Validator.config['scripts']['deactivate_alarm'])

  	    alarm_time = Time.parse(response[:message].attributes["aTs"])
  	    expect(alarm_time).to be_within(1.minute).of Time.now.utc
  	    expect(response[:message].attributes['rvs']).to eq([{
  	      "n":"detector","v":"1"},
  	      {"n":"type","v":"loop"},
  	      {"n":"errormode","v":"on"},
  	      {"n":"manual","v":"True"},
  	      {"n":"logicerror","v":"always_off"}
  	    ])
  	  ensure
  	    system(Validator.config['scripts']['deactivate_alarm'])
  	  end
  	end
  end

end
