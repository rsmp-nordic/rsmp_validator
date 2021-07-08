RSpec.describe "Traffic Light Controller" do
  include StatusHelpers

  describe 'Unknown Statuses' do
    it 'responds with NotAck to invalid status request code' do |example|
      Validator::Site.connected do |task,supervisor,site|
        site.log "Requesting non-existing status S0000", level: :test
        expect {
          status_list = convert_status_list( S0000:[:status] )
          site.request_status Validator.config['main_component'], status_list, collect: {
            timeout: Validator.config['timeouts']['command_response']
          },
          validate: false
        }.to raise_error(RSMP::MessageRejected)
      end
    end

    it 'responds with NotAck to invalid status request name' do |example|
      Validator::Site.connected do |task,supervisor,site|
        site.log "Requesting non-existing status S0001 name", level: :test
        expect {
          status_list = convert_status_list( S0001:[:bad] )
          site.request_status Validator.config['main_component'], status_list, collect: {
            timeout: Validator.config['timeouts']['command_response']
          },
          validate: false
        }.to raise_error(RSMP::MessageRejected)
      end
    end
  end
end
