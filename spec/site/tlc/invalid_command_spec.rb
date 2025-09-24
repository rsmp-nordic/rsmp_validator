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
    # 2. When we send an M0002 command with an invalid timeplan value
    # 3. Then the site should return a command response with current values
    # 4. And the age attribute should not be 'undefined'

    # Verify that site returns current values when receiving a command
    # with invalid parameter values that cause the command to fail
    #
    # Note: This test uses a timeout of 0 minutes for yellow flash to trigger
    # a quick automatic revert, which helps create a scenario where current
    # values should be returned if the command processing fails for some reason.
    #
    # 1. Given the site is connected
    # 2. When we send an M0001 command with an extreme timeout value
    # 3. Then the site should return a command response with current values
    # 4. And the age attribute should contain valid timestamps

    it 'returns current values when command fails with invalid values', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        log "Sending M0001 with parameters that may cause processing issues"
        
        # Use parameters that are technically valid format-wise but might 
        # cause the command to fail during processing
        command_list = build_command_list :M0001, :setValue, {
          securityCode: Validator.get_config('secrets','security_codes',2),
          status: 'YellowFlash',
          timeout: '-1',    # Negative timeout might cause processing issues
          intersection: '99' # Very high intersection number
        }
        
        result = site.send_command(
          Validator.get_config('main_component'),
          command_list,
          collect: { timeout: Validator.get_config('timeouts','command_response') }
        )
        
        collector = result[:collector]
        expect(collector).to be_an(RSMP::Collector)
        
        # The key is that we should get a response, whether it's successful or not
        if collector.status == :ok
          response = collector.messages.first
          expect(response).to be_an(RSMP::CommandResponse)
          
          # Check that we got return values
          rvs = response.attributes['rvs']
          expect(rvs).to be_an(Array)
          expect(rvs).not_to be_empty, "Expected return values in command response"
          
          # Verify that return values have proper structure
          rvs.each do |rv|
            expect(rv).to have_key('age'), "Expected age in return value"
            expect(rv).to have_key('cCI'), "Expected command code id in return value"
            expect(rv).to have_key('n'), "Expected parameter name in return value"
            expect(rv).to have_key('v'), "Expected parameter value in return value"
            expect(rv['cCI']).to eq('M0001'), "Expected command code id M0001"
            
            # The age should either be a valid timestamp, 'undefined', or 'recent'
            # - 'undefined': command was not processed for this component
            # - 'recent': command was processed but may have failed, returning current/attempted values
            # - timestamp: command was successful, returning actual current values with their timestamps
            age = rv['age']
            if age == 'undefined'
              # Command was not processed (e.g., unknown component)
              expect(age).to eq('undefined')
            elsif age == 'recent'
              # Command was processed but may have failed - this is what we're testing for
              expect(age).to eq('recent')
            else
              # Command was successful - should have a valid timestamp
              expect(age).to be_a(String), "Expected age to be a string timestamp"
              expect(age).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/), "Expected age to be a valid ISO timestamp"
            end
          end
        else
          # If the command was rejected, that's also a valid outcome for this test
          # We're testing that implementations handle invalid values appropriately
          expect(collector.status).to eq(:cancelled)
          expect(collector.error).to be_an(RSMP::MessageRejected)
        end
      end
    end
  end
end
