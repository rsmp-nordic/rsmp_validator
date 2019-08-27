RSpec.describe "RSMP site connection" do
  
  def check_connection_sequence versions, expected
    RSMP::SiteTester.reconnected('rsmp_versions' => [versions].flatten) do |task,supervisor,site|
      items = supervisor.archive.capture task, with_message: true, num: expected.size, timeout: 1, from: 0
      got = items.map { |item| item[:message] }.map { |message| [message.direction.to_s, message.type] }
      expect(got).to eq(expected)
      expect(site.ready?).to be true
    end
  end

  context 'Version 3.1.1' do
    it 'exchanges correct connection sequence' do
      check_connection_sequence '3.1.1', [
        ['in','Version'],
        ['out','MessageAck'],
        ['out','Version'],
        ['in','MessageAck'],
        ['in','Watchdog'],
        ['out','MessageAck'],
        ['out','Watchdog'],
        ['in','MessageAck']
      ]
    end
  end

  context 'Version 3.1.2' do
    it 'exchanges correct connection sequence' do
      check_connection_sequence '3.1.2', [
        ['in','Version'],
        ['out','MessageAck'],
        ['out','Version'],
        ['in','MessageAck'],
        ['in','Watchdog'],
        ['out','MessageAck'],
        ['out','Watchdog'],
        ['in','MessageAck']
      ]
    end
  end

  context 'Version 3.1.3' do
    it 'exchanges correct connection sequence' do
      check_connection_sequence '3.1.3', [
        ['in','Version'],
        ['out','MessageAck'],
        ['out','Version'],
        ['in','MessageAck'],
        ['in','Watchdog'],
        ['out','MessageAck'],
        ['out','Watchdog'],
        ['in','MessageAck'],
        ['in','AggregatedStatus'],
        ['out','MessageAck']
      ]
    end
  end

  context 'Version 3.1.4' do
    it 'exchanges correct connection sequence' do
      check_connection_sequence '3.1.4', [
        ['in','Version'],
        ['out','MessageAck'],
        ['out','Version'],
        ['in','MessageAck'],
        ['in','Watchdog'],
        ['out','MessageAck'],
        ['out','Watchdog'],
        ['in','MessageAck'],
        ['in','AggregatedStatus'],
        ['out','MessageAck']
      ]
    end
  end

end
