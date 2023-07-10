RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::StatusHelpers

  context 'receiving a status request with an unknown component id' do

    # Verify that site reponds with NotAck when receive a status request
    # with an unknown component id
    #
    # 1. Given the site is connected
    # 2. When we send a status request with an unknown component id
    # 3. Then the site should return a status response with q=undefined

    it 'return a command response with age=undefined' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Sending M0001 with bad component id"
        status_list = convert_status_list( S0001:[:signalgroupstatus] )
        result = site.request_status(
          'bad',
          status_list,
          collect: { timeout: Validator.config['timeouts']['status_response'] },
          validate: false
        )
        collector = result[:collector]
        expect(collector).to be_an(RSMP::Collector)
        expect(collector.status).to eq(:ok)
        response = collector.messages.first
        expect(response).to be_an(RSMP::StatusResponse)
        sS = response.attributes['sS']
        expect(sS).to be_an(Array)
        sS.each do |s|
          q = s['q']
          expect(q).to eq('undefined'), "expected sS q attribute to be 'undefined', got #{s.inspect}"
        end
      end
    end
  end


  context 'receiving a status request for an unknown status' do
    # Verify that site returns NotAck when receiving
    # a request for an unknown status
    #
    # 1. Given the site is connected
    # 2. When we send a non-existing S000 status request
    # 3. Then the site should return NotAck
    it 'returns NotAck' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Requesting non-existing status S0000"
        status_list = convert_status_list( S0000:[:status] )
        result = site.request_status(
          Validator.config['main_component'], status_list,
          collect: { timeout: Validator.config['timeouts']['status_response'] },
          validate: false
        )
        collector = result[:collector]
        expect(collector).to be_an(RSMP::Collector)
        expect(collector.status).to eq(:cancelled)
        expect(collector.error).to be_an(RSMP::MessageRejected)
      end
    end
  end

  context 'receiving a status request with an invalid status name' do
    # Verify that site returns NotAck when receiving
    # a request for an unknown status
    #
    # 1. Given the site is connected
    # 2. When we send an S0001 request with the stauts name 'bad'
    # 3. Then the site should return NotAck
    it 'returns NotAck' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Requesting S0001 with non-existing status name"
        status_list = convert_status_list( S0001:[:bad] )
        result = site.request_status(
          Validator.config['main_component'], status_list,
          collect: { timeout: Validator.config['timeouts']['status_response'] },
          validate: false
        )
        collector = result[:collector]
        expect(collector).to be_an(RSMP::Collector)
        expect(collector.status).to eq(:cancelled)
        expect(collector.error).to be_an(RSMP::MessageRejected)
      end
    end
  end
end
