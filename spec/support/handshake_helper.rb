# frozen_string_literal: true

module Validator
  # Helpers for validating the sequence of messages during rsmp connection establishment
  module HandshakeHelper
    # Wait for the site to connect and collect a specified number of messages,
    # which can then be analysed.
    def get_connection_message(core_version, length)
      timeout = Validator.get_config('timeouts', 'ready')
      got = nil

      Validator::SiteTester.isolated(
        'collect' => { timeout: timeout, num: length, ingoing: true, outgoing: true },
        'guest' => {
          'rsmp_versions' => [core_version]
        }
      ) do |task, _supervisor, site|
        expect(site.ready?).to be true
        collector = site.collector
        collector.use_task task
        collector.wait!
        got = collector.messages.map { |message| "#{message.direction}:#{message.type}" }
      end
      got
    rescue Async::TimeoutError
      raise "Did not collect #{length} messages within #{timeout}s"
    end

    # Validate the connection sequence for core 3.1.1, 3.1.2 and 3.1.3
    # In these earliser version of core, both the site and and the supervisor
    # sends a Version message simulatenously as soon as the connection is opened,
    # and then acknowledged.
    # We therefore cannot expect a specific sequence of the first four messages,
    # but we can check that the set of messages is correct
    # The same is the case with the next four messages, which is the exchange of Watchdogs
    def check_sequence_3_1_1_to_3_1_3(core_version)
      expected_version_messages = expected_version_exchange_messages
      expected_watchdog_messages = expected_watchdog_exchange_messages

      length = expected_version_messages.length +
               expected_watchdog_messages.length
      got = get_connection_message core_version, length

      expect_sequence_part!(
        got[0..3],
        expected: expected_version_messages,
        forbidden: ['in:AggregatedStatus', 'in:Watchdog', 'in:Alarm'],
        context: 'version exchange'
      )

      expect_sequence_part!(
        got[4..7],
        expected: expected_watchdog_messages,
        forbidden: ['in:AggregatedStatus', 'in:Alarm'],
        context: 'watchdog exchange'
      )
    end

    def expected_version_exchange_messages
      [
        'in:Version',
        'out:MessageAck',
        'out:Version',
        'in:MessageAck'
      ]
    end

    def expected_watchdog_exchange_messages
      [
        'in:Watchdog',
        'out:MessageAck',
        'out:Watchdog',
        'in:MessageAck'
      ]
    end

    def expect_sequence_part!(got_part, expected:, forbidden:, context:)
      forbidden.each do |message|
        type = message.split(':').last
        expect(got_part.include?(message)).to(
          be_falsy,
          "#{type} not allowed during #{context}: #{got_part}"
        )
      end

      expect(got_part).to(
        match_array(expected),
        "Wrong #{context} part, must contain #{expected}, got #{got_part}"
      )
    end

    # Validate the connection sequence for core 3.1.4 and later
    # From 3.1.4, the site must send a Version first, so the sequence
    # is fixed and can be directly verified
    def check_sequence_3_1_4_or_later(version)
      expected = [
        'in:Version',
        'out:MessageAck',
        'out:Version',
        'in:MessageAck',
        'in:Watchdog',
        'out:MessageAck',
        'out:Watchdog',
        'in:MessageAck'
      ]
      got = get_connection_message version, expected.length
      expect(got).to eq(expected)
    end

    def check_sequence(version)
      case version
      when '3.1.1', '3.1.2', '3.1.3'
        check_sequence_3_1_1_to_3_1_3 version
      when '3.1.4', '3.1.5', '3.2', '3.2.1', '3.2.2'
        check_sequence_3_1_4_or_later version
      else
        raise "Unkown rsmp version #{version}"
      end
    end
  end
end
