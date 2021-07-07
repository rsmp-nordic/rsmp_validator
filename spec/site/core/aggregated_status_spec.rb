RSpec.describe 'Core' do
  include CommandHelpers

  describe 'Aggregated Status' do
    # Verify that the controller responds to an aggregated status request.
    #
    # 1. Given the site is connected
    # 2. Request aggregated status 
    # 3. Expect aggregated status response before timeout
    it 'responds to aggregated status request', rsmp: '>=3.1.5' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        log_confirmation "request aggregated status" do
          site.request_aggregated_status Validator.config['main_component'], collect: {
            timeout: Validator.config['timeouts']['status_response']
          }
        end
        expect {
          raise "bad"
        }.not_to raise_error
      end
    end
  end
end
