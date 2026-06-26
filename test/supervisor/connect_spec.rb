describe 'Supervisor' do
  describe 'Connection Sequence' do
    def connection_collect_options(timeout, length)
      {
        timeout: timeout,
        num: length,
        ingoing: true,
        outgoing: true
      }
    end

    def prepare_and_wait_for_collector(supervisor_proxy)
      collector = supervisor_proxy.collector
      collector.use_task Async::Task.current
      collector.wait!
    end

    def direction_and_type_pairs(messages)
      messages.map { |message| [message.direction.to_s, message.type] }
    end

    def get_connection_message(core_version, length)
      timeout = RSMP::Validator.get_config('timeouts', 'ready')
      got_messages = nil
      with_supervisor(:isolated,
                      'core_version' => core_version,
                      'collect' => {
                        **connection_collect_options(timeout, length)
                      }) do |supervisor_proxy|
        prepare_and_wait_for_collector(supervisor_proxy)
        assert(supervisor_proxy.ready?, 'expected site proxy to be ready')
        got_messages = supervisor_proxy.collector.messages
      end
      direction_and_type_pairs(got_messages)
    rescue Async::TimeoutError
      raise "Did not collect #{length} messages within #{timeout}s"
    end

    def check_sequence_v311(core_version)
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

      assert(expected_version_messages.all? { |e| got_version_messages.include?(e) },
             'expected version messages not found in connection sequence')
      assert(got_watchdog_messages.all? { |e| expected_watchdog_messages.include?(e) },
             'unexpected watchdog messages in connection sequence')
    end

    def check_sequence_v314(version)
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

    def check_sequence_v330(version)
      expected = [
        %w[out Version],
        %w[in MessageAck],
        %w[in Version],
        %w[out MessageAck],
        %w[out Watchdog],
        %w[in MessageAck],
        %w[in Watchdog],
        %w[out MessageAck],
        %w[out ComponentList],
        %w[in MessageAck],
        %w[out AggregatedStatus],
        %w[in MessageAck]
      ]
      got = get_connection_message version, expected.length
      expect(got).to eq(expected)
    end

    def check_sequence(version)
      case version
      when '3.1.1', '3.1.2', '3.1.3'
        check_sequence_v311 version
      when '3.1.4', '3.1.5', '3.2', '3.2.1', '3.2.2'
        check_sequence_v314 version
      when '3.3.0'
        check_sequence_v330 version
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
    it 'exchanges correct connection sequence of rsmp version 3.1.1' do
      skip 'requires core == 3.1.1' unless RSMP::Validator.core_matches?('3.1.1')
      check_sequence '3.1.1'
    end

    # Verify the connection sequence when using rsmp core 3.1.2
    #
    # 1. Given the site is connected and using core 3.1.2
    # 2. Send and receive handshake messages
    # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.2
    # 4. Expect the connection sequence to be complete
    it 'exchanges correct connection sequence of rsmp version 3.1.2' do
      skip 'requires core == 3.1.2' unless RSMP::Validator.core_matches?('3.1.2')
      check_sequence '3.1.2'
    end

    # Verify the connection sequence when using rsmp core 3.1.3
    #
    # 1. Given the site is connected and using core 3.1.3
    # 2. Send and receive handshake messages
    # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.3
    # 4. Expect the connection sequence to be complete
    it 'exchanges correct connection sequence of rsmp version 3.1.3' do
      skip 'requires core == 3.1.3' unless RSMP::Validator.core_matches?('3.1.3')
      check_sequence '3.1.3'
    end

    # Verify the connection sequence when using rsmp core 3.1.4
    #
    # 1. Given the site is connected and using core 3.1.4
    # 2. Send and receive handshake messages
    # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.4
    # 4. Expect the connection sequence to be complete
    it 'exchanges correct connection sequence of rsmp version 3.1.4' do
      skip 'requires core == 3.1.4' unless RSMP::Validator.core_matches?('3.1.4')
      check_sequence '3.1.4'
    end

    # Verify the connection sequence when using rsmp core 3.1.5
    #
    # 1. Given the site is connected and using core 3.1.5
    # 2. Send and receive handshake messages
    # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.5
    # 4. Expect the connection sequence to be complete
    it 'exchanges correct connection sequence of rsmp version 3.1.5' do
      skip 'requires core == 3.1.5' unless RSMP::Validator.core_matches?('3.1.5')
      check_sequence '3.1.5'
    end

    # Verify the connection sequence when using rsmp core 3.2
    #
    # 1. Given the site is connected and using core 3.2
    # 2. Send and receive handshake messages
    # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.5
    # 4. Expect the connection sequence to be complete
    it 'exchanges correct connection sequence of rsmp version 3.2' do
      skip 'requires core == 3.2' unless RSMP::Validator.core_matches?('3.2')
      check_sequence '3.2'
    end

    # Verify the connection sequence when using rsmp core 3.2.1
    #
    # 1. Given the site is connected and using core 3.2.1
    # 2. Send and receive handshake messages
    # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.5
    # 4. Expect the connection sequence to be complete
    it 'exchanges correct connection sequence of rsmp version 3.2.1' do
      skip 'requires core == 3.2.1' unless RSMP::Validator.core_matches?('3.2.1')
      check_sequence '3.2.1'
    end

    # Verify the connection sequence when using rsmp core 3.2.2
    #
    # 1. Given the site is connected and using core 3.2.2
    # 2. Send and receive handshake messages
    # 3. Expect the handshake messages to be in the specified sequence corresponding to version 3.1.5
    # 4. Expect the connection sequence to be complete
    it 'exchanges correct connection sequence of rsmp version 3.2.2' do
      skip 'requires core == 3.2.2' unless RSMP::Validator.core_matches?('3.2.2')
      check_sequence '3.2.2'
    end

    # Verify the connection sequence when using rsmp core 3.3.0
    #
    # 1. Given the site is connected and using core 3.3.0
    # 2. Send and receive handshake messages
    # 3. Expect the ComponentList before application traffic
    # 4. Expect the connection sequence to be complete
    it 'exchanges correct connection sequence of rsmp version 3.3.0' do
      skip 'requires core == 3.3.0' unless RSMP::Validator.core_matches?('3.3.0')
      check_sequence '3.3.0'
    end
  end
end
