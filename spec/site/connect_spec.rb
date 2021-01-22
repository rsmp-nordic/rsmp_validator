RSpec.describe "RSMP site connection" do

  def check_connection_sequence version, expected
    TestSite.isolated(
      'rsmp_versions' => [version],
      'collect' => expected.size
    ) do |task,supervisor,site|
      site.collector.collect task, timeout: RSMP_CONFIG['ready_timeout']
      items = site.collector.items
      got = items.map { |item| item[:message] }.map { |message| [message.direction.to_s, message.type] }
      expect(got).to eq(expected)
      expect(site.ready?).to be true
    end
  end

  def check_sequence_from_3_1_1 version
    check_connection_sequence version, [
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

  def check_sequence_from_3_1_3 version
    check_connection_sequence version, [
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

  def check_sequence version
    case version
    when '3.1.1', '3.1.2'
      check_sequence_from_3_1_1 version
    when '3.1.3', '3.1.4', '3.1.5'
      check_sequence_from_3_1_3 version
    else
      raise "Unkown rsmp version #{version}"
    end
  end

  it 'exchanges correct connection sequence of rsmp version 3.1.1', rsmp: '3.1.1' do |example|
    check_sequence '3.1.1'
  end

  it 'exchanges correct connection sequence of rsmp version 3.1.2', rsmp: '3.1.2' do |example|
    check_sequence '3.1.2'
  end

  it 'exchanges correct connection sequence of rsmp version 3.1.3', rsmp: '3.1.3' do |example|
    check_sequence '3.1.3'
  end

  it 'exchanges correct connection sequence of rsmp version 3.1.4', rsmp: '3.1.4' do |example|
    check_sequence '3.1.4'
  end

  it 'exchanges correct connection sequence of rsmp version 3.1.5', rsmp: '3.1.5' do |example|
    check_sequence '3.1.5'
  end

end
