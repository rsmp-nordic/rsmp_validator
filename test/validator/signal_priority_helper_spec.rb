require_relative '../../lib/rsmp/validator'

describe RSMP::Validator::Helpers::SignalPriority::RequestHelper do
  let(:proxy) { Struct.new(:tlc).new(Struct.new(:use_soc?).new(true)) }
  let(:helper) { subject.new(proxy, component: 'main', signal_group_id: 'sg1', timeout: 0.05) }
  let(:request_id) { helper.instance_variable_get(:@request_id) }

  def update(state, **options)
    item = {
      'sCI' => options.fetch(:code, 'S0033'),
      'n' => options.fetch(:name, 'status'),
      'q' => options.fetch(:quality, 'recent'),
      's' => [{ 'r' => options.fetch(:id, request_id), 's' => state }]
    }
    RSMP::StatusUpdate.new(
      'cId' => options.fetch(:component, 'main'),
      'sS' => [item]
    ).tap { |message| message.direction = :in }
  end

  it 'retains transitions received before the first expectation' do
    Async do
      received = update('received')
      activated = update('activated')
      helper.receive(received)
      helper.receive(activated)

      expect(helper.expect(:received)).to be(:equal?, received)
      expect(helper.expect(:activated)).to be(:equal?, activated)
    end.wait
  end

  it 'retains back-to-back transitions while waiting for the first state' do
    Async do |task|
      waiter = task.async { helper.expect(:received) }
      received = update('received')
      activated = update('activated')
      helper.receive(received)
      helper.receive(activated)

      expect(waiter.wait).to be(:equal?, received)
      expect(helper.expect(:activated)).to be(:equal?, activated)
    end.wait
  end

  %w[completed stale].each do |terminal_state|
    it "retains early #{terminal_state} updates and skips repeated states" do
      Async do
        %w[received received activated activated].each { |state| helper.receive(update(state)) }
        terminal = update(terminal_state)
        helper.receive(terminal)

        helper.expect(:received)
        helper.expect(:activated)
        expect(helper.expect(terminal_state)).to be(:equal?, terminal)
      end.wait
    end
  end

  it 'filters unrelated requests, status fields, qualities and components' do
    Async do
      [{ id: 'unrelated' }, { code: 'S9999' }, { name: 'other' },
       { quality: 'undefined' }, { component: 'other' }].each do |options|
        helper.receive(update('received', **options))
      end
      received = update('received')
      helper.receive(received)

      expect(helper.expect(:received)).to be(:equal?, received)
      expect(helper.messages).to be(:empty?)
    end.wait
  end

  it 'does not reuse an earlier state to satisfy a later expectation' do
    Async do
      helper.receive(update('activated'))
      helper.receive(update('received'))
      helper.expect(:received)

      expect { helper.expect(:activated) }.to raise_exception(RSMP::OperationError)
    end.wait
  end

  it 'times out when no update arrives' do
    Async do
      expect { helper.expect(:received) }.to raise_exception(RSMP::OperationError)
    end.wait
  end

  it 'does not restart the timeout when non-matching states arrive' do
    Async do |task|
      finished = false
      producer = task.async do
        12.times do
          helper.receive(update('received'))
          task.sleep(0.01)
        end
        finished = true
      end

      expect { helper.expect(:activated) }.to raise_exception(RSMP::OperationError)
      expect(finished).to be == false
    ensure
      producer&.stop
    end.wait
  end
end
