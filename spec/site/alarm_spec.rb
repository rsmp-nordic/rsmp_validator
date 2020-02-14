RSpec.describe 'RSMP site alarm' do
  it 'A0301 detector error (hardware)' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = COMPONENT_CONFIG['detector_logic_prefix'] + "001"

      site.log "Waiting for alarm", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        response = site.wait_for_alarm component: component, aCId: 'A0301',
          aSp: 'Issue', aS: 'Active', timeout: RSMP_CONFIG['alarm_timeout']
      end.to_not raise_error, "Did not receive alarm"
      
      delay = Time.now - start_time
      site.log "alarm confirmed after #{delay.to_i}s", level: :test
    end
  end
end
