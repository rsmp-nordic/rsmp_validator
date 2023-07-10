RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::CommandHelpers

  context 'receiving an command with an unknown component id' do

    # Verify that site reponds with NotAck when receive a command
    # with an unknown component id
    #
    # 1. Given the site is connected
    # 2. When we send a command with an unknown component id
    # 3. Then the site return a command response with age=undefined

    it 'return a command response with age=undefined' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Sending M0001"
        command_list = build_command_list :M0001, :setValue, {
          securityCode: Validator.config['secrets']['security_codes'][2],
          status: 'NormalControl',
          timeout: 0,
          intersection: 0
        }
        # Note: the rsmp tlc emulator automatically adds compoents that it
        # doesn't know, so you don't have to configure them manually in the supervisor
        # However, it will refuse to add a component with an empty string ''.
        result = site.send_command '', command_list,
          collect: { timeout: Validator.config['timeouts']['command_response'] },
          validate: false     # disable validation of outgoing message
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

  context 'receiving an unknown command code id' do

    # Verify that site returns NotAck when receiving an unknown command
    #
    # 1. Given the site is connected
    # 2. When we send a non-existing M0000 command
    # 3. Then the site return NotAck
    
    it 'returns NotAck' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Sending non-existing command M0000"
        command_list = build_command_list :M0000, :bad, {}
        result = site.send_command Validator.config['main_component'], command_list,
          collect: { timeout: Validator.config['timeouts']['command_response'] },
          validate: false     # disable validation of outgoing message
        collector = result[:collector]
        expect(collector).to be_an(RSMP::Collector)
        expect(collector.status).to eq(:cancelled)
        expect(collector.error).to be_an(RSMP::MessageRejected)
      end
    end
  end

  context 'receiving a command with a missing attribute' do
    it 'returns NotAck' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Sending M0001 with 'status' attribute missing"
        command_list = build_command_list :M0001, :setValue, {
            securityCode: '1111',
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

  context 'receiving a command with a bad command name n' do
    it 'returns NotAck' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Sending M0001"
        # for M0001, cO should be :setValue, here we use the incorrect :bad
        command_list = build_command_list :M0001, :bad, {
            securityCode: '1111',
            intersection: '0',
            timeout: '0'
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
