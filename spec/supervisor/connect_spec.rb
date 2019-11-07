RSpec.describe "RSMP supervisor connection" do

  def check_connection_sequence versions, expected
    options = {
      'rsmp_versions' => [versions].flatten,
      'send_after_connect' => true
    }
    TestSupervisor.reconnected(options) do |task,supervisor_proxy,site|
      items = site.archive.capture task, level: :log, with_message: true, num: expected.size, timeout: 1, from: 0
      got = items.map { |item| item[:message] }.map { |message| [message.direction.to_s, message.type] }
      expect(got).to eq(expected)
      expect(supervisor_proxy.ready?).to be true
    end
  end

  context 'Version 3.1.1' do
    it 'exchanges correct connection sequence' do
      check_connection_sequence '3.1.1', [
        ['out','Version'],
        ['in','MessageAck'],
        ['in','Version'],
        ['out','MessageAck'],
        ['out','Watchdog'],
        ['in','MessageAck'],
        ['in','Watchdog'],
        ['out','MessageAck'],
        ['out','AggregatedStatus'],
        ['in','MessageAck']
      ]
    end
  end

  context 'Version 3.1.3' do
    it 'exchanges correct connection sequence' do
      check_connection_sequence '3.1.3', [
        ['out','Version'],
        ['in','MessageAck'],
        ['in','Version'],
        ['out','MessageAck'],
        ['out','Watchdog'],
        ['in','MessageAck'],
        ['in','Watchdog'],
        ['out','MessageAck'],
        ['out','AggregatedStatus'],
        ['in','MessageAck']
      ]
    end
  end

  context 'Version 3.1.4' do
    it 'exchanges correct connection sequence' do
      check_connection_sequence '3.1.4', [
        ['out','Version'],
        ['in','MessageAck'],
        ['in','Version'],
        ['out','MessageAck'],
        ['out','Watchdog'],
        ['in','MessageAck'],
        ['in','Watchdog'],
        ['out','MessageAck'],
        ['out','AggregatedStatus'],
        ['in','MessageAck']
      ]
    end
  end

end
