RSpec.describe "RSMP site status" do
  
  # Check that we can *subscribe* to status messages.
  # The test subscribes to S0001 (signal group status), but
  # this is arbitrary as we simply want to check that
  # the subscription mechanism works.
  #
  # 1. subscribe
  # 1. check that we receive a status update with a predefined time
  # 1. unsubscribe
  
  it 'responds to valid status subscription' do |example|
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_list = [{'sCI'=>'S0001','n'=>'signalgroupstatus','uRt'=>RSMP_CONFIG['status_update_rate'].to_s }]
      site.subscribe_to_status component, status_list, collect: {
        timeout: SUPERVISOR_CONFIG['status_update_timeout']
      }
    ensure
      unsubscribe_list = status_list.map { |item| item.slice('sCI','n') }
      site.unsubscribe_to_status component, unsubscribe_list
    end
  end

end
