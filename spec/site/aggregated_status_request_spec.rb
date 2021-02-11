RSpec.describe "RSMP aggregated status" do
  include CommandHelpers

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
