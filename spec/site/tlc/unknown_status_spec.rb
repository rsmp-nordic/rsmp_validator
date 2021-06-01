RSpec.describe "Traffic Light Controller" do
  include StatusHelpers

  it 'responds with NotAck to invalid status request code' do |example|
    TestSite.connected do |task,supervisor,site|
      site.log "Requesting non-existing status S0000", level: :test
      expect {
        status_list = convert_status_list( S0000:[:status] )
        site.request_status MAIN_COMPONENT, status_list, collect: {
          timeout: TIMEOUTS_CONFIG['command_response']
        },
        validate: false
      }.to raise_error(RSMP::MessageRejected)
    end
  end

  it 'responds with NotAck to invalid status request name' do |example|
    TestSite.connected do |task,supervisor,site|
      site.log "Requesting non-existing status S0001 name", level: :test
      expect {
        status_list = convert_status_list( S0001:[:bad] )
        site.request_status MAIN_COMPONENT, status_list, collect: {
          timeout: TIMEOUTS_CONFIG['command_response']
        },
        validate: false
      }.to raise_error(RSMP::MessageRejected)
    end
  end

end
