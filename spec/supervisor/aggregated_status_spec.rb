RSpec.describe 'RSMP supervisor' do
  it 'receives aggretated status' do
    TestSupervisor.connected do |task,supervisor_proxy,site|
      component = site.components.first[1]   # value of first key/value pair, ie. first component
      component.set_aggregated_status :high_priority_alarm
      supervisor_proxy.wait_for_acknowledgements 1
    end
  end
end
