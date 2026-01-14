# frozen_string_literal: true

RSpec.describe 'Supervisor' do
  describe 'Connection Sequence' do
    def get_connection_message(core_version, length)
      got = nil
      Validator::SupervisorTester.isolated(
        'rsmp_versions' => [core_version],
        'collect' => {
          timeout: Validator.get_config('timeouts', 'ready'),
          num: length,
          ingoing: true,
          outgoing: true
        }
      ) do |task, _supervisor, site_proxy|
        collector = site_proxy.collector
        collector.use_task task
        collector.wait!
        expect(site_proxy.ready?).to be true
        got = site_proxy.collector.messages.map { |message| [message.direction.to_s, message.type] }
      end
      got
    rescue Async::TimeoutError
      raise "Did not collect #{length} messages within #{timeout}s"
    end

    def check_sequence_3_1_1(core_version)
      # in earlier core version, both sides sends a Version
      # message simulatenously. we therefore cannot expect
      # a specific sequence
      # but we can expect a set of messages

      expected_version_messages = [
        %w[out Version],
        %w[in MessageAck],
        %w[in Version],
        %w[out MessageAck]
      ]
      expected_watchdog_messages = [
        %w[out Watchdog],
        %w[in MessageAck],
        %w[in Watchdog],
        %w[out MessageAck]
      ]

      length = expected_version_messages.length +
               expected_watchdog_messages.length

      got = get_connection_message core_version, length
      got_version_messages = got[0..3]
      got_watchdog_messages = got[4..7]

      expect(got_version_messages).to include(*expected_version_messages)
      expect(expected_watchdog_messages).to include(*got_watchdog_messages)
    end

    def check_sequence_3_1_4(version)
      expected = [
        %w[out Version],
        %w[in MessageAck],
        %w[in Version],
        %w[out MessageAck],
        %w[out Watchdog],
        %w[in MessageAck],
        %w[in Watchdog],
        %w[out MessageAck],
        %w[out AggregatedStatus],
        %w[in MessageAck]
      ]
      got = get_connection_message version, expected.length
      expect(got).to eq(expected)
    end

    def check_sequence(version)
      case version
      when '3.1.1', '3.1.2', '3.1.3'
        check_sequence_3_1_1 version
      when '3.1.4', '3.1.5', '3.2', '3.2.1', '3.2.2'
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
    it 'exchanges correct connection sequence of rsmp version 3.1.1', core: '3.1.1' do |_example|
      check_sequence '3.1.1'
    end

    # Verify the connection sequence when using rsmp core 3.1.2
    #
    # 1. Given the site is connected and using core 3.1.2
    # 2. Send and receive handshake messages
    # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.2
    # 4. Expect the connection sequence to be complete
    it 'exchanges correct connection sequence of rsmp version 3.1.2', core: '3.1.2' do |_example|
      check_sequence '3.1.2'
    end

    # Verify the connection sequence when using rsmp core 3.1.3
    #
    # 1. Given the site is connected and using core 3.1.3
    # 2. Send and receive handshake messages
    # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.3
    # 4. Expect the connection sequence to be complete
    it 'exchanges correct connection sequence of rsmp version 3.1.3', core: '3.1.3' do |_example|
      check_sequence '3.1.3'
    end

    # Verify the connection sequence when using rsmp core 3.1.4
    #
    # 1. Given the site is connected and using core 3.1.4
    # 2. Send and receive handshake messages
    # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.4
    # 4. Expect the connection sequence to be complete
    it 'exchanges correct connection sequence of rsmp version 3.1.4', core: '3.1.4' do |_example|
      check_sequence '3.1.4'
    end

    # Verify the connection sequence when using rsmp core 3.1.5
    #
    # 1. Given the site is connected and using core 3.1.5
    # 2. Send and receive handshake messages
    # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.5
    # 4. Expect the connection sequence to be complete
    it 'exchanges correct connection sequence of rsmp version 3.1.5', core: '3.1.5' do |_example|
      check_sequence '3.1.5'
    end

    # Verify the connection sequence when using rsmp core 3.2
    #
    # 1. Given the site is connected and using core 3.2
    # 2. Send and receive handshake messages
    # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.5
    # 4. Expect the connection sequence to be complete
    it 'exchanges correct connection sequence of rsmp version 3.2', core: '3.2' do |_example|
      check_sequence '3.2'
    end

    # Verify the connection sequence when using rsmp core 3.2.1
    #
    # 1. Given the site is connected and using core 3.2.1
    # 2. Send and receive handshake messages
    # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.5
    # 4. Expect the connection sequence to be complete
    it 'exchanges correct connection sequence of rsmp version 3.2.1', core: '3.2.1' do |_example|
      check_sequence '3.2.1'
    end

    # Verify the connection sequence when using rsmp core 3.2.2
    #
    # 1. Given the site is connected and using core 3.2.2
    # 2. Send and receive handshake messages
    # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.5
    # 4. Expect the connection sequence to be complete
    it 'exchanges correct connection sequence of rsmp version 3.2.2', core: '3.2.2' do |_example|
      check_sequence '3.2.2'
    end
  end
end
