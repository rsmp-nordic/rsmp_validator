RSpec.describe 'Traffic Light Controller' do
  include CommandHelpers
  include StatusHelpers

  def check_scripts
    raise "Aborting test because script config is missing" unless SCRIPT_PATHS
    raise "Aborting test because script config is missing" unless SCRIPT_PATHS['activate_alarm']
    raise "Aborting test because script config is missing" unless SCRIPT_PATHS['deactivate_alarm']
  end

  it 'A0302 detector error (logic error)', :script, sxl: '>=1.0.7' do |example|
    check_scripts
    TestSite.connected do |task,supervisor,site|
      component = COMPONENT_CONFIG['detector_logic'].keys.first
      system(SCRIPT_PATHS['activate_alarm'])
      site.log "Waiting for alarm", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        response = site.wait_for_alarm task, component: component, aCId: 'A0302',
          aSp: 'Issue', aS: 'Active', timeout: TIMEOUTS_CONFIG['alarm']
      end.to_not raise_error, "Did not receive alarm"

      delay = Time.now - start_time
      site.log "alarm confirmed after #{delay.to_i}s", level: :test
      system(SCRIPT_PATHS['deactivate_alarm'])

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
      system(SCRIPT_PATHS['deactivate_alarm'])
    end
  end

  skip 'Acknowledge alarm', :script do |example|
    check_scripts
    TestSite.connected do |task,supervisor,site|
      component = COMPONENT_CONFIG['detector_logic'].keys.first
      system(SCRIPT_PATHS['activate_alarm'])
      site.log "Waiting for alarm", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        response = site.wait_for_alarm task, component: component, aCId: 'A0302',
          aSp: 'Issue', aS: 'Active', timeout: TIMEOUTS_CONFIG['alarm']
      end.to_not raise_error, "Did not receive alarm"
  
      alarm_code_id = 'A0302'
      message = @site.send_alarm_acknowledgement @component, alarm_code_id
  
      delay = Time.now - start_time
      site.log "alarm confirmed after #{delay.to_i}s", level: :test
      
      expect do
        response = @site.wait_for_alarm_acknowledged_response message: message, component: @component, timeout: TIMEOUTS_CONFIG['alarm']
      end.to_not raise_error
      
      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::AlarmAcknowledgedResponse)
      expect(response.attributes['cId']).to eq(@component)
    ensure 
      system(SCRIPT_PATHS['deactivate_alarm'])
    end
  end

  it 'buffers alarms during disconnects', :script, sxl: '>=1.0.7' do |example|
    check_scripts
    component = COMPONENT_CONFIG['detector_logic'].keys.first
    TestSite.isolated do |task,supervisor,site|
    end      
    # Activate alarm 
    system(SCRIPT_PATHS['activate_alarm'])

    TestSite.isolated do |task,supervisor,site|
      @site = site
      log_confirmation "Waiting for alarm" do
        message, response = nil,nil
        expect do
          response = site.wait_for_alarm task, component: component, aCId: 'A0302',
            aSp: 'Issue', aS: 'Active', timeout: TIMEOUTS_CONFIG['alarm']
        end.to_not raise_error, "Did not receive alarm"

      end
      system(SCRIPT_PATHS['deactivate_alarm'])

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
      system(SCRIPT_PATHS['deactivate_alarm'])
    end
  end
end
