describe 'Supervisor' do
  # Validate behaviour related to aggregated status messages
  describe 'Aggregated Status' do
    # Validate that the supervisor responds correctly when we send an aggregated status message
    it 'receives aggregated status' do
      with_supervisor(:connected) do |supervisor_proxy|
        component = supervisor_proxy.node.find_component Validator.get_config('main_component')

        # setting ':collect' will cause set_aggregated_status() to wait for the
        # outgoing aggregated status is acknowledged
        component.set_aggregated_status :high_priority_alarm, collect!: {
          timeout: Validator.get_config('timeouts', 'acknowledgement'),
          num: 1
        }
      end
    end
  end
end
