describe 'Supervisor::Tlc::TestHints' do
  # Validate that the supervisor sends M0002 and acknowledges the command response.
  #
  # 1. Given the supervisor is connected and test scenarios are enabled
  # 2. When we send the M0002.set_plan hint
  # 3. Then the supervisor should send M0002
  # 4. And the simulated site should send a CommandResponse
  # 5. And the supervisor should acknowledge our CommandResponse
  it 'sends M0002 and acknowledges its response' do
    with_supervisor(:isolated, sxl: '>=1.0.7') do |proxy|
      with_scenario(proxy, 'M0002.set_plan') do |scenario|
        expect_or_stop(scenario.send_hint).to be_a(RSMP::Result::Success)

        result = scenario.wait_for_command('M0002')
        expect_or_stop(result).to be_a(RSMP::Result::Success)

        _command, response = result.value
        result = scenario.wait_for_ack(response)
        expect_or_stop(result).to be_a(RSMP::Result::Success)
      end
    end
  end

  # Validate that the supervisor subscribes to S0014, acknowledges an update, and unsubscribes.
  #
  # 1. Given the supervisor is connected and test scenarios are enabled
  # 2. When we send the S0014.subscribe_once hint
  # 3. Then the supervisor should subscribe to S0014
  # 4. When we send a StatusUpdate
  # 5. Then the supervisor should acknowledge that update
  # 6. And unsubscribe from the same status
  it 'subscribes to S0014, acknowledges an update, and unsubscribes' do
    with_supervisor(:isolated, sxl: '>=1.0.7') do |proxy|
      with_scenario(proxy, 'S0014.subscribe_once') do |scenario|
        expect_or_stop(scenario.send_hint).to be_a(RSMP::Result::Success)

        result = scenario.wait_for_subscribe('S0014')
        expect_or_stop(result).to be_a(RSMP::Result::Success)

        _subscribe, update = result.value
        result = scenario.wait_for_ack(update)
        expect_or_stop(result).to be_a(RSMP::Result::Success)

        result = scenario.wait_for_unsubscribe
        expect_or_stop(result).to be_a(RSMP::Result::Success)
      end
    end
  end
end
