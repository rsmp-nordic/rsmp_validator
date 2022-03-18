RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::StatusHelpers

  context 'receiving an invalid status request code' do
    it 'returns NotAck ' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Requesting non-existing status S0000"
        status_list = convert_status_list( S0000:[:status] )
        result = site.request_status Validator.config['main_component'], status_list,
          collect: { timeout: Validator.config['timeouts']['command_response'] },
          validate: false
        collector = result[:collector]
        expect(collector).to be_an(RSMP::Collector)
        expect(collector.status).to eq(:cancelled)
        expect(collector.error).to be_an(RSMP::MessageRejected)
      end
    end
  end

  context 'receiving an invalid status request name' do
    it 'returns NotAck' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Requesting non-existing status S0001 name"
        status_list = convert_status_list( S0001:[:bad] )
        result = site.request_status Validator.config['main_component'], status_list,
          collect: { timeout: Validator.config['timeouts']['command_response'] },
          validate: false
                collector = result[:collector]
        expect(collector).to be_an(RSMP::Collector)
        expect(collector.status).to eq(:cancelled)
        expect(collector.error).to be_an(RSMP::MessageRejected)
      end
    end
  end
end
