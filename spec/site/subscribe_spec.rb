RSpec.describe "RSMP site status" do
  it 'responds to valid status request' do |example|
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_list = [{'sCI'=>'S0001','n'=>'signalgroupstatus','uRt'=>'0'}]
      site.wait_for_status_updates(site.task,{
        component: component,
        status_list: status_list,
        timeout: SUPERVISOR_CONFIG['status_update_timeout']
      }) do
        message = site.subscribe_to_status component, status_list
      end
      unsubscribe_list = status_list.map do |item|
        item.reject! { |k,v| k=='uRt' }
      end
      site.unsubscribe_to_status component, unsubscribe_list
    end
  end

end
