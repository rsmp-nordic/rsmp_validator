RSpec.describe 'RSMP supervisor' do
  it 'receives aggretated status' do
    TestSupervisor.connected do |task,site,supervisor_proxy|
      component = site.find_component TestSupervisor.config['main_component']

      # setting ':collect' will cause set_aggregated_status() to wait for the
      # outgoing aggregated status is acknowledged
      component.set_aggregated_status :high_priority_alarm, collect: {
        timeout: TestSupervisor.config['timeouts']['acknowledgement']
      }
    end
  end
end
