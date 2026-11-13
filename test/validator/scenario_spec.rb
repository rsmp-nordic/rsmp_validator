require_relative '../../lib/rsmp/validator'

describe RSMP::Validator::Scenario do
  let(:proxy) do
    Object.new.tap do |object|
      object.extend RSMP::Distributor
      object.initialize_distributor
      object.define_singleton_method(:send_test_hint) { |id| RSMP::Result.success(id) }
    end
  end
  let(:scenario) { subject.new(proxy, 'M0002.set_plan', timeout: 0.03) }
  let(:command) { message('CommandRequest', :in, 'cId' => 'TC', 'arg' => [{ 'cCI' => 'M0002' }]) }
  let(:response) { message('CommandResponse', :out, 'cId' => 'TC', 'rvs' => [{ 'cCI' => 'M0002' }]) }
  let(:ack) { message('MessageAck', :in, 'oMId' => response.m_id) }

  def message(type, direction, attributes = {})
    RSMP.const_get(type).new(attributes).tap { |item| item.direction = direction }
  end

  def deliver_exchange
    [command, response, ack].each { |item| proxy.distribute(item) }
  end

  it 'keeps an exchange and its acknowledgement received before either wait' do
    Async do
      scenario.collect do
        expect(scenario.send_hint.value).to be == 'M0002.set_plan'
        deliver_exchange
        result = scenario.wait_for_command('M0002')
        expect(result).to be_a(RSMP::Result::Success)
        expect(result.value).to be == [command, response]
        expect(scenario.wait_for_ack(response).value).to be == ack
      end
      expect(proxy.receivers).to be(:empty?)
    end.wait
  end

  it 'retains back-to-back messages while the test waits for the command' do
    Async do |task|
      scenario.collect do
        producer = task.async do |child|
          child.sleep(0.001)
          deliver_exchange
        end
        expect(scenario.wait_for_command('M0002').value).to be == [command, response]
        expect(scenario.wait_for_ack(response).value).to be == ack
        producer.wait
      end
    end.wait
  end

  it 'fails if a different command arrives' do
    Async do
      scenario.collect do
        command.attributes['arg'] = [{ 'cCI' => 'M0001' }]
        deliver_exchange
        result = scenario.wait_for_command('M0002')
        expect(result.failure.code).to be == :unexpected_message
        expect(result.failure.context[:message]).to be == command
      end
    end.wait
  end

  it 'requires the response to match the command component and code' do
    Async do
      [{ 'cId' => 'OTHER' }, { 'rvs' => [{ 'cCI' => 'M0001' }] }].each do |changes|
        scenario.collect do
          proxy.distribute(command)
          proxy.distribute(message('CommandResponse', :out, response.attributes.merge(changes)))
          expect(scenario.wait_for_command('M0002').failure.code).to be == :unexpected_message
        end
      end
    end.wait
  end

  it 'ignores unrelated acknowledgements and checks the direction and original ID' do
    Async do
      scenario.collect do
        proxy.distribute(message('MessageAck', :in, 'oMId' => command.m_id))
        proxy.distribute(message('MessageAck', :out, 'oMId' => response.m_id))
        proxy.distribute(ack)
        expect(scenario.wait_for_ack(response).value).to be == ack
      end
    end.wait
  end

  let(:subscription) do
    message('StatusSubscribe', :in, 'cId' => 'TC', 'sS' => [{ 'sCI' => 'S0014', 'n' => 'status' }])
  end
  let(:update) do
    message('StatusUpdate', :out, 'cId' => 'TC', 'sS' => [{ 'sCI' => 'S0014', 'n' => 'status', 's' => 1 }])
  end
  let(:unsubscribe) do
    message('StatusUnsubscribe', :in, 'cId' => 'TC', 'sS' => [{ 'sCI' => 'S0014', 'n' => 'status' }])
  end

  it 'retains a complete subscription exchange received before the waits' do
    Async do
      scenario.collect do
        acknowledgement = message('MessageAck', :in, 'oMId' => update.m_id)
        [subscription, update, acknowledgement, unsubscribe].each { |item| proxy.distribute(item) }
        result = scenario.wait_for_subscribe('S0014')
        expect(result).to be_a(RSMP::Result::Success)
        expect(result.value).to be == [subscription, update]
        expect(scenario.wait_for_ack(update).value).to be == acknowledgement
        expect(scenario.wait_for_unsubscribe.value).to be == unsubscribe
      end
    end.wait
  end

  it 'waits for our outgoing update after receiving a subscription' do
    Async do |task|
      scenario.collect do
        proxy.distribute(subscription)
        producer = task.async do |child|
          child.sleep(0.001)
          proxy.distribute(update)
        end
        expect(scenario.wait_for_subscribe('S0014').value).to be == [subscription, update]
        producer.wait
      end
    end.wait
  end

  it 'times out if no outgoing update follows the subscription' do
    Async do
      scenario.collect do
        proxy.distribute(subscription)
        proxy.distribute(message('StatusUpdate', :in, update.attributes))
        expect(scenario.wait_for_subscribe('S0014').failure.code).to be == :timeout
      end
    end.wait
  end

  it 'checks that the update uses the subscribed component and status fields' do
    Async do
      [{ 'cId' => 'OTHER' }, { 'sS' => [{ 'sCI' => 'S0014', 'n' => 'source' }] }].each do |changes|
        scenario.collect do
          proxy.distribute(subscription)
          proxy.distribute(message('StatusUpdate', :out, update.attributes.merge(changes)))
          expect(scenario.wait_for_subscribe('S0014').failure.code).to be == :unexpected_message
        end
      end
    end.wait
  end

  it 'checks that unsubscribe cancels the same status fields' do
    Async do
      scenario.collect do
        [subscription, update].each { |item| proxy.distribute(item) }
        wrong = unsubscribe.attributes.merge('sS' => [{ 'sCI' => 'S0014', 'n' => 'source' }])
        proxy.distribute(message('StatusUnsubscribe', :in, wrong))
        expect(scenario.wait_for_subscribe('S0014')).to be_a(RSMP::Result::Success)
        expect(scenario.wait_for_unsubscribe.failure.code).to be == :unexpected_message
      end
    end.wait
  end

  it 'ignores unsubscribes for another component before accepting the matching one' do
    Async do
      scenario.collect do
        [subscription, update].each { |item| proxy.distribute(item) }
        proxy.distribute(message('StatusUnsubscribe', :in, unsubscribe.attributes.merge('cId' => 'OTHER')))
        proxy.distribute(unsubscribe)
        expect(scenario.wait_for_subscribe('S0014')).to be_a(RSMP::Result::Success)
        expect(scenario.wait_for_unsubscribe.value).to be == unsubscribe
      end
    end.wait
  end

  it 'times out if only another component unsubscribes' do
    Async do
      scenario.collect do
        [subscription, update].each { |item| proxy.distribute(item) }
        proxy.distribute(message('StatusUnsubscribe', :in, unsubscribe.attributes.merge('cId' => 'OTHER')))
        expect(scenario.wait_for_subscribe('S0014')).to be_a(RSMP::Result::Success)
        result = scenario.wait_for_unsubscribe
        expect(result.failure.code).to be == :timeout
        expect(result.failure.message).to be(:include?, 'on TC')
      end
    end.wait
  end

  it 'requires a subscription from the current collection before waiting for unsubscribe' do
    Async do
      scenario.collect do
        expect { scenario.wait_for_unsubscribe }.to raise_exception(RuntimeError)
        [subscription, update].each { |item| proxy.distribute(item) }
        expect(scenario.wait_for_subscribe('S0014')).to be_a(RSMP::Result::Success)
      end
      scenario.collect do
        expect { scenario.wait_for_unsubscribe }.to raise_exception(RuntimeError)
      end
    end.wait
  end

  it 'ignores unrelated status codes throughout the subscription exchange' do
    Async do
      scenario.collect do
        unrelated = { 'cId' => 'TC', 'sS' => [{ 'sCI' => 'S0001', 'n' => 'status' }] }
        proxy.distribute(message('StatusSubscribe', :in, unrelated))
        proxy.distribute(subscription)
        proxy.distribute(message('StatusUpdate', :out, unrelated))
        proxy.distribute(update)
        proxy.distribute(message('StatusUnsubscribe', :in, unrelated))
        proxy.distribute(unsubscribe)
        expect(scenario.wait_for_subscribe('S0014').value).to be == [subscription, update]
        expect(scenario.wait_for_unsubscribe.value).to be == unsubscribe
      end
    end.wait
  end

  it 'ignores hints and unrelated rejections admitted by the message filter' do
    Async do
      scenario.collect do
        proxy.distribute(message('MessageNotAck', :out, 'oMId' => SecureRandom.uuid, 'rea' => 'test hint'))
        proxy.distribute(message('MessageNotAck', :in, 'oMId' => SecureRandom.uuid, 'rea' => 'unrelated rejection'))
        proxy.distribute(message('StatusSubscribe', :out, subscription.attributes))
        [subscription, update].each { |item| proxy.distribute(item) }
        expect(scenario.wait_for_subscribe('S0014').value).to be == [subscription, update]
      end
    end.wait
  end

  it 'times out if the requested status code never arrives' do
    Async do
      scenario.collect do
        proxy.distribute(message('StatusSubscribe', :in, 'sS' => [{ 'sCI' => 'S0001', 'n' => 'status' }]))
        result = scenario.wait_for_subscribe('S0014')
        expect(result.failure.code).to be == :timeout
        expect(result.failure.message).to be(:include?, 'S0014')
      end
    end.wait
  end

  it 'matches a subscription containing the requested code alongside another code' do
    Async do
      scenario.collect do
        subscription.attributes['sS'] << { 'sCI' => 'S0001', 'n' => 'status' }
        proxy.distribute(subscription)
        proxy.distribute(update)
        expect(scenario.wait_for_subscribe('S0014').value).to be == [subscription, update]
      end
    end.wait
  end

  it 'does not reuse an acknowledgement that preceded the command response' do
    Async do
      scenario.collect do
        [command, ack, response].each { |item| proxy.distribute(item) }
        expect(scenario.wait_for_command('M0002')).to be_a(RSMP::Result::Success)
        expect(scenario.wait_for_ack(response).failure.code).to be == :timeout
      end
    end.wait
  end

  it 'returns a failure for a rejection of the response' do
    Async do
      scenario.collect do
        proxy.distribute(message('MessageNotAck', :in, 'oMId' => response.m_id, 'rea' => 'not accepted'))
        result = scenario.wait_for_ack(response)
        expect(result.failure.code).to be == :message_rejected
        expect(result.failure.message).to be(:include?, 'not accepted')
      end
    end.wait
  end

  %i[invalid_message connection_ended missing_acknowledgement].each do |type|
    it "returns #{type} failures even if the exchange is already buffered" do
      Async do
        scenario.collect do
          deliver_exchange
          failure = RSMP::Failure.new(code: type, message: 'test failure', source: :peer)
          proxy.distribute_event(RSMP::Event.new(type: type, source: proxy, failure: failure))
          expect(scenario.wait_for_command('M0002').failure).to be == failure
        end
      end.wait
    end
  end

  it 'wakes a waiter when the connection ends' do
    Async do |task|
      scenario.collect do
        failure = RSMP::Failure.new(code: :disconnected, message: 'connection ended', source: :transport)
        producer = task.async do |child|
          child.sleep(0.001)
          proxy.distribute_event(RSMP::Event.new(type: :connection_ended, source: proxy, failure: failure))
        end
        expect(scenario.wait_for_command('M0002').failure).to be == failure
        producer.wait
      end
    end.wait
  end

  it 'does not restart the timeout for unrelated traffic' do
    Async do |task|
      scenario.collect do
        finished = false
        producer = task.async do |child|
          20.times do
            proxy.distribute(message('Watchdog', :in))
            child.sleep(0.01)
          end
          finished = true
        end
        result = scenario.wait_for_command('M0002')
        expect(result.failure.code).to be == :timeout
        expect(result.failure.message).to be(:include?, 'CommandRequest')
        expect(finished).to be == false
        producer.stop
      end
    end.wait
  end

  it 'cleans up when an expectation stops the test and clears messages before reuse' do
    Async do
      catch(:rsmp_validator_test_failure) do
        scenario.collect do
          deliver_exchange
          throw :rsmp_validator_test_failure unless proxy.receivers.empty?
        end
      end
      expect(proxy.receivers).to be(:empty?)
      scenario.collect do
        expect(scenario.wait_for_ack(response).failure.code).to be == :timeout
      end
    end.wait
  end

  it 'requires collection before sending or waiting' do
    expect { scenario.send_hint }.to raise_exception(RuntimeError)
    expect { scenario.wait_for_command('M0002') }.to raise_exception(RuntimeError)
  end

  it 'rejects nested collection without stopping the outer collection' do
    Async do
      scenario.collect do
        expect { scenario.collect { :unexpected } }.to raise_exception(RuntimeError)
        expect(proxy.receivers.size).to be == 1
        expect(proxy.receivers.first).to be_a(RSMP::Queue)
        deliver_exchange
        expect(scenario.wait_for_command('M0002')).to be_a(RSMP::Result::Success)
      end
      expect(proxy.receivers).to be(:empty?)
    end.wait
  end
end
