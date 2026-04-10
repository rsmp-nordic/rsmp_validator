describe 'Site::Tlc::InvalidStatus' do
  include Validator::Helpers::Status

  # Verify that site_proxy reponds with q=undefined when receiving a
  # status request with an unknown component id.
  #
  # 1. Given the site_proxy is connected
  # 2. When we send a status request with an unknown component id
  # 3. Then the site_proxy should return a status response with q=undefined

  it 'return a command response with age=undefined when component id is unknown' do
    with_site(:connected, core: '>=3.1.3') do |site_proxy|
      log 'Sending M0001 with bad component id'
      status_list = convert_status_list(S0001: [:signalgroupstatus])
      result = site_proxy.request_status(
        'bad',
        status_list,
        collect: { timeout: Validator.get_config('timeouts', 'status_response') },
        validate: false
      )
      collector = result[:collector]
      expect(collector).to be_a(RSMP::Collector)
      expect(collector.status).to eq(:ok)
      response = collector.messages.first
      expect(response).to be_a(RSMP::StatusResponse)
      ss = response.attributes['sS']
      expect(ss).to be_a(Array)
      ss.each do |s|
        q = s['q']
        expect(q).to eq('undefined')
      end
    end
  end

  # Verify that site_proxy returns NotAck when receiving
  # a request for an unknown status
  #
  # 1. Given the site_proxy is connected
  # 2. When we send a non-existing S000 status request
  # 3. Then the site_proxy should return NotAck
  it 'returns NotAck when status code is unknown' do
    with_site(:connected) do |site_proxy|
      log 'Requesting non-existing status S0000'
      status_list = convert_status_list(S0000: [:status])
      result = site_proxy.request_status(
        Validator.get_config('main_component'), status_list,
        collect: { timeout: Validator.get_config('timeouts', 'status_response') },
        validate: false
      )
      collector = result[:collector]
      expect(collector).to be_a(RSMP::Collector)
      expect(collector.status).to eq(:cancelled)
      expect(collector.error).to be_a(RSMP::MessageRejected)
    end
  end

  # Verify that site_proxy returns NotAck when receiving
  # a request for an unknown status
  #
  # 1. Given the site_proxy is connected
  # 2. When we send an S0001 request with the stauts name 'bad'
  # 3. Then the site_proxy should return NotAck
  it 'returns NotAck when status name is unknown' do
    with_site(:connected) do |site_proxy|
      log 'Requesting S0001 with non-existing status name'
      status_list = convert_status_list(S0001: [:bad])
      result = site_proxy.request_status(
        Validator.get_config('main_component'), status_list,
        collect: { timeout: Validator.get_config('timeouts', 'status_response') },
        validate: false
      )
      collector = result[:collector]
      expect(collector).to be_a(RSMP::Collector)
      expect(collector.status).to eq(:cancelled)
      expect(collector.error).to be_a(RSMP::MessageRejected)
    end
  end
end
