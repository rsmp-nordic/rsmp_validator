module Validator

  # Helpers for validating the sequence of messages during rsmp connection establishment
  module HandshakeHelper

    # Wait for the site to connect and collect a specified number of messages,
    # which can then be analysed.
    def get_connection_message core_version, length
      timeout = Validator.config['timeouts']['ready']
      got = nil

      Validator::Site.isolated(
        'collect' => {timeout: timeout, num: length, ingoing: true, outgoing: true},
        'guest' => {
          'rsmp_versions' => [core_version],
        }
      ) do |task,supervisor,site|
        expect(site.ready?).to be true
        collector = site.collector
        collector.use_task task
        collector.wait!
        got = collector.messages.map { |message| "#{message.direction}:#{message.type}" }
      end
      got
    rescue Async::TimeoutError => e
      raise "Did not collect #{length} messages within #{timeout}s"
    end

    # Validate the connection sequence for core 3.1.1, 3.1.2 and 3.1.3    
    # In these earliser version of core, both the site and and the supervisor
    # sends a Version message simulatenously as soon as the connection is opened,
    # and then acknowledged.
    # We therefore cannot expect a specific sequence of the first four messages,
    # but we can check that the set of messages is correct
    # The same is the case with the next four messages, which is the exchange of Watchdogs
    def check_sequence_3_1_1_to_3_1_3 core_version
      expected_version_messages = [
        'in:Version',
        'out:MessageAck',
        'out:Version',
        'in:MessageAck',
      ]
      expected_watchdog_messages = [
        'in:Watchdog',
        'out:MessageAck',
        'out:Watchdog',
        'in:MessageAck',
      ]

      length = expected_version_messages.length +
               expected_watchdog_messages.length

      got = get_connection_message core_version, length

      got_version_messages = got[0..3]
      expect( got_version_messages.include?('in:AggregatedStatus') ).to be_falsy, "AggregatedStatus not allowed during version exchange: #{got_version_messages}"
      expect( got_version_messages.include?('in:Watchdog') ).to be_falsy, "Watchdog not allowed during version exchange: #{got_version_messages}"
      expect( got_version_messages.include?('in:Alarm') ).to be_falsy, "Alarms not allowed during version exchange: #{got_version_messages}"
      expect(got_version_messages).to match_array(expected_version_messages),
        "Wrong version part, must contain #{expected_version_messages}, got #{got_version_messages}"

      got_watchdog_messages = got[4..7]
      expect( got_watchdog_messages.include?('in:AggregatedStatus') ).to be_falsy, "AggregatedStatus not allowed during watchdog exchange: #{got_watchdog_messages}"
      expect( got_watchdog_messages.include?('in:Alarm') ).to be_falsy, "Alarms not allowed during watchdog exchange: #{got_version_messages}"
      expect(got_watchdog_messages).to match_array(expected_watchdog_messages),
        "Wrong watchdog part, must contain #{expected_watchdog_messages}, got #{got_watchdog_messages}"
    end

    # Validate the connection sequence for core 3.1.4 and later
    # From 3.1.4, the site must send a Version first, so the sequence
    # is fixed and can be directly verified    
    def check_sequence_3_1_4_or_later version
      expected = [
        'in:Version',
        'out:MessageAck',
        'out:Version',
        'in:MessageAck',
        'in:Watchdog',
        'out:MessageAck',
        'out:Watchdog',
        'in:MessageAck',
     ]
      got = get_connection_message version, expected.length
      expect(got).to eq(expected)
    end

    def check_sequence version
      case version
      when '3.1.1', '3.1.2', '3.1.3'
        check_sequence_3_1_1_to_3_1_3 version
      when '3.1.4', '3.1.5'
        check_sequence_3_1_4_or_later version
      else
        raise "Unkown rsmp version #{version}"
      end
    end
  end
end


RSpec.describe 'Site::Core' do
  describe 'Connection Sequence' do
    include Validator::HandshakeHelper

    # Verify the connection sequence when using rsmp core 3.1.1
    #
    # 1. Given the site is connected and using core 3.1.1
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.1
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.1.1', core: '3.1.1' do |example|
      check_sequence '3.1.1'
    end

    # Verify the connection sequence when using rsmp core 3.1.2
    #
    # 1. Given the site is connected and using core 3.1.2
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.2
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.1.2', core: '3.1.2' do |example|
      check_sequence '3.1.2'
    end

    # Verify the connection sequence when using rsmp core 3.1.3
    #
    # 1. Given the site is connected and using core 3.1.3
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.3
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.1.3', core: '3.1.3' do |example|
      check_sequence '3.1.3'
    end

    # Verify the connection sequence when using rsmp core 3.1.4
    #
    # 1. Given the site is connected and using core 3.1.4
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.4
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.1.4', core: '3.1.4' do |example|
      check_sequence '3.1.4'
    end

    # Verify the connection sequence when using rsmp core 3.1.5
    #
    # 1. Given the site is connected and using core 3.1.5
    # 2. When handshake messages are sent and received
    # 3. Then the handshake messages should be in the specified sequence corresponding to version 3.1.5
    # 4. And the connection sequence should be complete
    it 'is correct for rsmp version 3.1.5',  core: '3.1.5' do |example|
      check_sequence '3.1.5'
    end
  end
end
