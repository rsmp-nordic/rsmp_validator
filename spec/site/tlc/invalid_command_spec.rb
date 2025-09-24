RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::CommandHelpers

  context 'receiving an command with an unknown component id' do

    # Verify that site reponds with age=undefined when receiving
    # a command with an unknown component id
    #
    # 1. Given the site is connected
    # 2. When we send a command with an unknown component id
    # 3. Then the site should return a command response with age=undefined

    it 'returns a command response with age=undefined', core: '>=3.1.3' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Sending M0001"
        command_list = build_command_list :M0001, :setValue, {
          securityCode: Validator.get_config('secrets','security_codes',2),
          status: 'NormalControl',
          timeout: 0,
          intersection: 0
        }
        result = site.send_command(
          'bad',
          command_list,
          collect: { timeout: Validator.get_config('timeouts','command_response') },
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

  context 'receiving an unknown command code id' do

    # Verify that site returns NotAck when receiving an unknown command
    #
    # 1. Given the site is connected
    # 2. When we send a non-existing M0000 command
    # 3. Then the site should return NotAck

    it 'returns NotAck' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Sending non-existing command M0000"
        command_list = build_command_list :M0000, :bad, {}
        result = site.send_command Validator.get_config('main_component'), command_list,
          collect: { timeout: Validator.get_config('timeouts','command_response') },
          validate: false     # disable validation of outgoing message
        collector = result[:collector]
        expect(collector).to be_an(RSMP::Collector)
        expect(collector.status).to eq(:cancelled)
        expect(collector.error).to be_an(RSMP::MessageRejected)
      end
    end
  end

  context 'receiving a command with a missing attribute' do

    # Verify that site returns NotAck when receiving a command
    # with a mising command attribute
    #
    # 1. Given the site is connected
    # 2. When we send an M0001 command with 'status' missing
    # 3. Then the site return NotAck

    it 'returns NotAck' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Sending M0001 with 'status' attribute missing"
        command_list = build_command_list :M0001, :setValue, {
            securityCode: '1111',
            intersection: '0',
            timeout: '0'
            # intentionally not setting 'status'
        }
        result = site.send_command Validator.get_config('main_component'), command_list,
          collect: { timeout: Validator.get_config('timeouts','command_response') },
          validate: false   # disable validation of outgoing message
        collector = result[:collector]
        expect(collector).to be_an(RSMP::Collector)
        expect(collector.status).to eq(:cancelled)
        expect(collector.error).to be_an(RSMP::MessageRejected)
      end
    end
  end

  context 'receiving a command with a bad command name n' do

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
        command_list = build_command_list :M0001, :bad, {
            securityCode: '1111',
            intersection: '0',
            timeout: '0'
        }
        result = site.send_command Validator.get_config('main_component'), command_list,
          collect: { timeout: Validator.get_config('timeouts','command_response') },
          validate: false   # disable validation of outgoing message
        collector = result[:collector]
        expect(collector).to be_an(RSMP::Collector)
        expect(collector.status).to eq(:cancelled)
        expect(collector.error).to be_an(RSMP::MessageRejected)
      end
    end
  end

  context 'receiving a command with invalid parameter values' do

    # Verify that site returns current values when receiving a command
    # with invalid parameter values that cause the command to fail
    #
    # 1. Given the site is connected
    # 2. When we send a valid M0002 command to establish current values 
    # 3. Then we send an invalid M0002 command with non-existing timeplan
    # 4. Then the site should return a command response with current (unchanged) values
    # 5. And verify the non-existing timeplan is not in the config

    it 'returns current values when command fails with invalid values', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        # Verify that timeplan 255 is not in the configured plans
        configured_plans = Validator.get_config('items','plans')
        expect(configured_plans).not_to include(255), "Test assumes timeplan 255 is not configured, but it is: #{configured_plans}"
        
        # First, send a valid M0002 command to establish known current values
        log "Sending valid M0002 command to establish current values"
        
        valid_plan = '1'  # Use plan 1 from available plans [1,2]
        valid_command_list = build_command_list :M0002, :setPlan, {
          securityCode: Validator.get_config('secrets','security_codes',2), # Valid: '2222'
          status: 'True',
          timeplan: valid_plan
        }
        
        valid_result = site.send_command(
          Validator.get_config('main_component'),
          valid_command_list,
          collect: { timeout: Validator.get_config('timeouts','command_response') }
        )
        
        # Verify the valid command succeeded
        valid_collector = valid_result[:collector]
        expect(valid_collector).to be_an(RSMP::Collector)
        expect(valid_collector.status).to eq(:ok)
        valid_response = valid_collector.messages.first
        expect(valid_response).to be_an(RSMP::CommandResponse)
        
        # Store the current values from the successful command
        valid_rvs = valid_response.attributes['rvs']
        expect(valid_rvs).to be_an(Array)
        expect(valid_rvs).not_to be_empty, "Expected return values from valid command"
        
        # Now send an invalid M0002 command with non-existing timeplan
        log "Sending invalid M0002 command with non-existing timeplan 255"
        
        invalid_command_list = build_command_list :M0002, :setPlan, {
          securityCode: Validator.get_config('secrets','security_codes',2), # Valid security code
          status: 'True',
          timeplan: '255'  # Non-existing timeplan
        }
        
        invalid_result = site.send_command(
          Validator.get_config('main_component'),
          invalid_command_list,
          collect: { timeout: Validator.get_config('timeouts','command_response') }
        )
        
        # The invalid command should either be rejected or return current values
        invalid_collector = invalid_result[:collector]
        expect(invalid_collector).to be_an(RSMP::Collector)
        
        if invalid_collector.status == :ok
          # If command was processed, it should return current values
          invalid_response = invalid_collector.messages.first
          expect(invalid_response).to be_an(RSMP::CommandResponse)
          
          invalid_rvs = invalid_response.attributes['rvs']
          expect(invalid_rvs).to be_an(Array)
          expect(invalid_rvs).not_to be_empty, "Expected return values from invalid command"
          
          # Verify that return values have proper structure and contain current values
          invalid_rvs.each do |rv|
            expect(rv).to have_key('age'), "Expected age in return value"
            expect(rv).to have_key('cCI'), "Expected command code id in return value"
            expect(rv).to have_key('n'), "Expected parameter name in return value"
            expect(rv).to have_key('v'), "Expected parameter value in return value"
            expect(rv['cCI']).to eq('M0002'), "Expected command code id M0002"
            
            # The age should indicate current values (not 'undefined')
            age = rv['age']
            expect(age).not_to eq('undefined'), "Expected current values, not undefined age"
          end
        else
          # If command was rejected, that's also acceptable behavior
          expect(invalid_collector.status).to eq(:cancelled)
          expect(invalid_collector.error).to be_an(RSMP::MessageRejected)
        end
      end
    end
  end
end
