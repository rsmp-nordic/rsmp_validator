RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::CommandHelpers

  context 'sending an invalid command request' do
    it 'returns NotAck' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Sending non-existing command M0000"
        command_list = build_command_list :M0000, :setForceDetectorLogic, {
            securityCode: '1111',
            status: 'True',
            mode: 'True'
        }
        result = site.send_command Validator.config['main_component'], command_list,
          collect: { timeout: Validator.config['timeouts']['command_response'] },
          validate: false
        collector = result[:collector]
        expect(collector).to be_an(RSMP::Collector)
        expect(collector.status).to eq(:cancelled)
        expect(collector.error).to be_an(RSMP::MessageRejected)
      end
    end
  end

  context 'sending an incomplete command request' do
    it 'returns NotAck' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Sending non-existing command M0001"
        command_list = build_command_list :M0001, :setForceDetectorLogic, {
            securityCode: '1111',
            intersection: '0',
            timeout: '0'
        }
        result = site.send_command Validator.config['main_component'], command_list,
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
