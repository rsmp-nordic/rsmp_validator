RSpec.describe "RSMP site connection" do

  def check_connection_sequence versions, expected
    TestSite.reconnected(
      'rsmp_versions' => versions,
      'collect' => expected.size
    ) do |task,supervisor,site|
      site.collector.collect task, timeout: RSMP_CONFIG['ready_timeout']
      items = site.collector.items
      got = items.map { |item| item[:message] }.map { |message| [message.direction.to_s, message.type] }
      expect(got).to eq(expected)
      expect(site.ready?).to be true
    end
  end

  context 'Version 3.1.1' do
    it 'exchanges correct connection sequence' do |example|
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
    it 'exchanges correct connection sequence', sxl: '1.0.7' do |example|
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
    it 'exchanges correct connection sequence' do |example|
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
    it 'exchanges correct connection sequence' do |example|
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
