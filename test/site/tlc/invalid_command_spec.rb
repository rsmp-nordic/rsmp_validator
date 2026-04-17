describe 'Site::Tlc::InvalidCommand' do
  # Verify that site_proxy reponds with age=undefined when receiving
  # a command with an unknown component id
  #
  # 1. Given the site_proxy is connected
  # 2. When we send a command with an unknown component id
  # 3. Then the site_proxy should return a command response with age=undefined

  it 'returns a command response with age=undefined if compoent id is unknown' do
    with_site(:connected, core: '>=3.1.3') do |site_proxy|
      log 'Sending M0001'
      command_list = RSMP::CommandList.new(:M0001, :setValue,
                                           securityCode: Validator.get_config('secrets', 'security_codes', 2),
                                           status: 'NormalControl',
                                           timeout: 0,
                                           intersection: 0).to_a
      result = site_proxy.send_command_and_collect(
        command_list,
        component: 'bad',
        within: Validator.get_config('timeouts', 'command_response'),
        validate: false # disable validation of outgoing message
      )
      expect(result).to be_a(RSMP::Collector)
      expect(result.status).to eq(:ok)
      response = result.messages.first
      expect(response).to be_a(RSMP::CommandResponse)
      rvs = response.attributes['rvs']
      expect(rvs).to be_a(Array)
      rvs.each do |rv|
        age = rv['age']
        expect(age).to eq('undefined')
      end
    end
  end

  # Verify that site_proxy returns NotAck when receiving an unknown command
  #
  # 1. Given the site_proxy is connected
  # 2. When we send a non-existing M0000 command
  # 3. Then the site_proxy should return NotAck

  it 'returns NotAck if command code id is unknown' do
    with_site(:connected) do |site_proxy|
      log 'Sending non-existing command M0000'
      command_list = RSMP::CommandList.new(:M0000, :bad, {}).to_a
      timeout = Validator.get_config('timeouts', 'command_response')

      collector = site_proxy.send_command_and_collect(command_list,
                                                      within: timeout,
                                                      validate: false) # disable schema validation of outgoing message
      expect(collector.status).to eq(:cancelled)
      expect(collector.error).to be_a(RSMP::MessageRejected)
    end
  end

  # Verify that site_proxy returns NotAck when receiving a command
  # with a mising command attribute
  #
  # 1. Given the site_proxy is connected
  # 2. When we send an M0001 command with 'status' missing
  # 3. Then the site_proxy return NotAck

  it 'returns NotAck if attribute is missing' do
    with_site(:connected) do |site_proxy|
      log "Sending M0001 with 'status' attribute missing"
      command_list = RSMP::CommandList.new(:M0001, :setValue,
                                           securityCode: '1111',
                                           intersection: '0',
                                           timeout: '0').to_a
      # intentionally not setting 'status'
      timeout = Validator.get_config('timeouts', 'command_response')
      collector = site_proxy.send_command_and_collect(command_list,
                                                      within: timeout,
                                                      validate: false) # disable validation of outgoing message
      expect(collector.status).to eq(:cancelled)
      expect(collector.error).to be_a(RSMP::MessageRejected)
    end
  end

  # Verify that site_proxy returns NotAck when receiving a command
  # with an unknown command name
  #
  # 1. Given the site_proxy is connected
  # 2. When we send an M0001 command with 'bad' as command name
  # 3. Then the site_proxy should return NotAck

  it 'returns NotAck if command name is bad' do
    with_site(:connected) do |site_proxy|
      log 'Sending M0001'
      # for M0001, cO should be :setValue, here we use the incorrect :bad
      command_list = RSMP::CommandList.new(:M0001, :bad,
                                           securityCode: '1111',
                                           intersection: '0',
                                           timeout: '0').to_a
      timeout = Validator.get_config('timeouts', 'command_response')
      collector = site_proxy.send_command_and_collect(command_list,
                                                      within: timeout,
                                                      validate: false) # disable validation of outgoing message
      expect(collector.status).to eq(:cancelled)
      expect(collector.error).to be_a(RSMP::MessageRejected)
    end
  end
end
