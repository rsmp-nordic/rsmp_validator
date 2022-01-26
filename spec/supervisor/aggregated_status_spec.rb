RSpec.describe 'Supervisor' do
  
  # Validate behaviour related to aggregated status messages 
  describe 'Aggregated Status' do

  # Validate that the supervisor responds correctly when we send an aggregated status message
    it 'receives aggregated status' do
      Validator::Supervisor.connected do |task,site,supervisor_proxy|
        component = site.find_component Validator.config['main_component']

        # setting ':collect' will cause set_aggregated_status() to wait for the
        # outgoing aggregated status is acknowledged
        component.set_aggregated_status :high_priority_alarm, collect!: {
          timeout: Validator.config['timeouts']['acknowledgement']
        }
      end
    end
  end
end