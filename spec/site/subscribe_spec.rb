RSpec.describe "RSMP site status" do
  it 'responds to valid status request' do |example|
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_list = [{'sCI'=>'S0001','n'=>'signalgroupstatus','uRt'=>'0'}]
      site.subscribe_to_status component, status_list, collect: {
        timeout: SUPERVISOR_CONFIG['status_update_timeout']
      }
      unsubscribe_list = status_list.map { |item| item.reject! { |k,v| k=='uRt' } }
      site.unsubscribe_to_status component, unsubscribe_list
    end
  end

end
