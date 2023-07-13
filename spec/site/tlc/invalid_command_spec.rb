RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::CommandHelpers

  context 'receiving an command with an unknown component id' do

    # Verify that site reponds with NotAck when receiving a command
    # request with an unknown component id
    #
    # 1. Given the site is connected
    # 2. When we send a command with an unknown component id
    # 3. Then the site should return a command response with age=undefined

    it 'returns a command response with age=undefined' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Sending M0001"
        command_list = build_command_list :M0001, :setValue, {
          securityCode: Validator.config['secrets']['security_codes'][2],
          timeout: 0,
          intersection: 0,
          status: 'NormalControl'
        }
        result = site.send_command(
          'bad', command_list,
          collect: { timeout: Validator.config['timeouts']['command_response'] },
          validate: false     # disable validation of outgoing message
        )
        collector = result[:collector]
        expect(collector).to be_an(RSMP::Collector)
        expect(collector.status).to eq(:ok)
        response = collector.messages.first
        expect(response).to be_an(RSMP::CommandResponse)
        rvs = response.attributes['rvs']
        expect(rvs).to be_an(Array)
        rvs.each do |rv|
          age = rv['age']
          expect(age).to eq('undefined'), "expected rvs age attribute to be 'undefined', got #{rv.inspect}"
        end
      end
    end
  end

  context 'receiving an unknown command request code id' do

    # Verify that site returns NotAck when receiving an unknown command
    #
    # 1. Given the site is connected
    # 2. When we send a non-existing M0000 command
    # 3. Then the site should return NotAck

    it 'returns NotAck' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Sending non-existing command M0000"
        command_list = build_command_list :M0000, :wrong, {
          status: 'wrong'
        }
        result = site.send_command Validator.config['main_component'], command_list,
          securityCode: Validator.config['secrets']['security_codes'][2],
          collect: { timeout: Validator.config['timeouts']['command_response'] },
          validate: false     # disable validation of outgoing message
        collector = result[:collector]
        expect(collector).to be_an(RSMP::Collector)
        expect(collector.status).to eq(:cancelled)
        expect(collector.error).to be_an(RSMP::MessageRejected)
      end
    end
  end

  context 'receiving a command request with a missing attribute' do

    # Verify that site returns NotAck when receiving a command
    # request with a missing command attribute
    #
    # 1. Given the site is connected
    # 2. When we send an M0001 command with the 'status' attribute missing
    # 3. Then the site return NotAck

    it 'returns NotAck' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Sending M0001 with empty 'status' attribute"
        command_list = build_command_list :M0001, :setValue, {
            securityCode: Validator.config['secrets']['security_codes'][2],
            intersection: '0',
            timeout: '0'
            # intentionally not setting 'status'
        }
        result = site.send_command Validator.config['main_component'], command_list,
          collect: { timeout: Validator.config['timeouts']['command_response'] },
          validate: false   # disable validation of outgoing message
        collector = result[:collector]
        expect(collector).to be_an(RSMP::Collector)
        expect(collector.status).to eq(:cancelled)
        expect(collector.error).to be_an(RSMP::MessageRejected)
      end
    end
  end

  context 'receiving a command request with a bad command name' do

    # Verify that site returns NotAck when receiving a command
    # with an unknown command name
    #
    # 1. Given the site is connected
    # 2. When we send an M0001 command with 'bad' as command name
    # 3. Then the site should return NotAck

    it 'returns NotAck' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Sending M0001"
        # for M0001, cO should be :setValue, here we use the incorrect :bad
        command_list = build_command_list :M0001, :wrong, {
            securityCode: Validator.config['secrets']['security_codes'][2],
            intersection: '0',
            timeout: '0',
            status: 'NormalControl'
        }
        result = site.send_command Validator.config['main_component'], command_list,
          collect: { timeout: Validator.config['timeouts']['command_response'] },
          validate: false   # disable validation of outgoing message
        collector = result[:collector]
        expect(collector).to be_an(RSMP::Collector)
        expect(collector.status).to eq(:cancelled)
        expect(collector.error).to be_an(RSMP::MessageRejected)
      end
    end
  end
end
