RSpec.describe "Traffic Light Controller" do

  def get_connection_message core_version, length
    got = nil
    TestSite.isolated(
      'rsmp_versions' => [core_version],
      'collect' => length
    ) do |task,supervisor,site|
      site.collector.collect task, timeout: RSMP_CONFIG['ready_timeout']
      expect(site.ready?).to be true
      got = site.collector.messages.map { |message| [message.direction.to_s, message.type] }
    end
    got
  end

  def check_sequence_3_1_1 core_version
    # in earlier core version, both sides sends a Version
    # message simulatenously. we therefore cannot expect
    # a specific sequence
    # but we can expect a set of messages

    expected_version_messages = [
      ['in','Version'],
      ['out','MessageAck'],
      ['out','Version'],
      ['in','MessageAck'],
    ]
    expected_watchdog_messages = [
      ['in','Watchdog'],
      ['out','MessageAck'],
      ['out','Watchdog'],
      ['in','MessageAck']
    ]

    length = expected_version_messages.length +
             expected_watchdog_messages.length

    got = get_connection_message core_version, length
    got_version_messages = got[0..3]
    got_watchdog_messages = got[4..7]

    expect(got_version_messages).to include(*expected_version_messages)
    expect(expected_watchdog_messages).to include(*got_watchdog_messages)
  end

  def check_sequence_3_1_4 version
    expected = [
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
    got = get_connection_message version, expected.length
    expect(got).to eq(expected)
  end

  def check_sequence version
    case version
    when '3.1.1', '3.1.2', '3.1.3'
      check_sequence_3_1_1 version
    when '3.1.4', '3.1.5'
      check_sequence_3_1_4 version
    else
      raise "Unkown rsmp version #{version}"
    end
  end

  # Verify the connection sequence when using rsmp core 3.1.1
  #
  # 1. Given the site is connected and using core 3.1.1
  # 2. Send and receive handshake messages
  # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.1
  # 4. Expect the connection sequence to be complete
  it 'exchanges correct connection sequence of rsmp version 3.1.1', rsmp: '3.1.1' do |example|
    check_sequence '3.1.1'
  end

  # Verify the connection sequence when using rsmp core 3.1.2
  #
  # 1. Given the site is connected and using core 3.1.2
  # 2. Send and receive handshake messages
  # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.2
  # 4. Expect the connection sequence to be complete
  it 'exchanges correct connection sequence of rsmp version 3.1.2', rsmp: '3.1.2' do |example|
    check_sequence '3.1.2'
  end

  # Verify the connection sequence when using rsmp core 3.1.3
  #
  # 1. Given the site is connected and using core 3.1.3
  # 2. Send and receive handshake messages
  # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.3
  # 4. Expect the connection sequence to be complete
  it 'exchanges correct connection sequence of rsmp version 3.1.3', rsmp: '3.1.3' do |example|
    check_sequence '3.1.3'
  end

  # Verify the connection sequence when using rsmp core 3.1.4
  #
  # 1. Given the site is connected and using core 3.1.4
  # 2. Send and receive handshake messages
  # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.4
  # 4. Expect the connection sequence to be complete
  it 'exchanges correct connection sequence of rsmp version 3.1.4', rsmp: '3.1.4' do |example|
    check_sequence '3.1.4'
  end

  # Verify the connection sequence when using rsmp core 3.1.5
  #
  # 1. Given the site is connected and using core 3.1.5
  # 2. Send and receive handshake messages
  # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.5
  # 4. Expect the connection sequence to be complete
  it 'exchanges correct connection sequence of rsmp version 3.1.5', rsmp: '3.1.5' do |example|
    check_sequence '3.1.5'
  end
end
