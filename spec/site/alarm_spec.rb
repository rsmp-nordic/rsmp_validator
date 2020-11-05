RSpec.describe 'RSMP site alarm' do
  it 'A0302 detector error (logic error)' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = COMPONENT_CONFIG['detector_logic'].keys.first
      system("~/activate_alarm.sh")
      site.log "Waiting for alarm", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        response = site.wait_for_alarm component: component, aCId: 'A0302',
          aSp: 'Issue', aS: 'Active', timeout: RSMP_CONFIG['alarm_timeout']
      end.to_not raise_error, "Did not receive alarm"
        
      delay = Time.now - start_time
      site.log "alarm confirmed after #{delay.to_i}s", level: :test
      system("~/deactivate_alarm.sh")
    end
  end
end