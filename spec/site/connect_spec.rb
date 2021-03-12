RSpec.describe "RSMP site connection" do

  def check_connection_sequence version, expected
    TestSite.isolated(
      'rsmp_versions' => [version],
      'collect' => expected.size
    ) do |task,supervisor,site|
      site.collector.collect task, timeout: RSMP_CONFIG['ready_timeout']
      got = site.collector.messages.map { |message| [message.direction.to_s, message.type] }
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

# Verify that the handshake sequence upon connection is correct for 3.1.1
#
# 1. Given the site is new, connected and version 3.1.1
# 2. Send and receive handshake messages
# 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.1
# 4. Expect the site to be ready
  it 'exchanges correct connection sequence of rsmp version 3.1.1', rsmp: '3.1.1' do |example|
    check_sequence '3.1.1'
  end

# Verify that the handshake sequence upon connection is correct for 3.1.2
#
# 1. Given the site is new, connected and version 3.1.2
# 2. Send and receive handshake messages
# 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.2
# 4. Expect the site to be ready
  it 'exchanges correct connection sequence of rsmp version 3.1.2', rsmp: '3.1.2' do |example|
    check_sequence '3.1.2'
  end

# Verify that the handshake sequence upon connection is correct for 3.1.3
#
# 1. Given the site is new, connected and version 3.1.3
# 2. Send and receive handshake messages
# 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.3
# 4. Expect the site to be ready
  it 'exchanges correct connection sequence of rsmp version 3.1.3', rsmp: '3.1.3' do |example|
    check_sequence '3.1.3'
  end

# Verify that the handshake sequence upon connection is correct for 3.1.4
#
# 1. Given the site is new, connected and version 3.1.4
# 2. Send and receive handshake messages
# 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.4
# 4. Expect the site to be ready
  it 'exchanges correct connection sequence of rsmp version 3.1.4', rsmp: '3.1.4' do |example|
    check_sequence '3.1.4'
  end

# Verify that the handshake sequence upon connection is correct for 3.1.5
#
# 1. Given the site is new, connected and version 3.1.5
# 2. Send and receive handshake messages
# 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.5
# 4. Expect the site to be ready
  it 'exchanges correct connection sequence of rsmp version 3.1.5', rsmp: '3.1.5' do |example|
    check_sequence '3.1.5'
  end

end
