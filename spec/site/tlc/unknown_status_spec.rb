RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::StatusHelpers

  context 'receiving an invalid status request code' do
    it 'returns NotAck ' do |example|
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
  end

  context 'receiving an invalid status request name' do
    it 'returns NotAck' do |example|
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
