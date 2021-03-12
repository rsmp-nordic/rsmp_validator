RSpec.describe "RSMP aggregated status" do
  include CommandHelpers

  # Verify that the controller responds to an aggregated status request.
  #
  # 1. Given the site is connected
  # 2. Request aggregated status 
  # 3. Expect aggregated status response before timeout
  it 'request aggregated status', rsmp: '>=3.1.5' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      log_confirmation "request aggregated status" do
        site.request_aggregated_status MAIN_COMPONENT, collect: {
          timeout: SUPERVISOR_CONFIG['status_response_timeout']
        }
      end
    end
  end
end
