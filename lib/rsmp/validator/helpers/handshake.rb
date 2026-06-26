module RSMP
  module Validator
    module Helpers
      # Helpers for validating the sequence of messages during RSMP connection establishment.
      module Handshake
        EXPECTED_VERSION_EXCHANGE_MESSAGES = [
          'in:Version',
          'out:MessageAck',
          'out:Version',
          'in:MessageAck'
        ].freeze

        EXPECTED_WATCHDOG_EXCHANGE_MESSAGES = [
          'in:Watchdog',
          'out:MessageAck',
          'out:Watchdog',
          'in:MessageAck'
        ].freeze

        EXPECTED_COMPONENT_LIST_MESSAGES = [
          'in:ComponentList',
          'out:MessageAck'
        ].freeze

        def get_connection_message(core_version, length)
          timeout = RSMP::Validator.get_config('timeouts', 'ready')
          got = nil

          RSMP::Validator::SiteTester.isolated(
            'collect' => { timeout: timeout, num: length, ingoing: true, outgoing: true },
            'sites' => { 'default' => { 'core_version' => core_version } }
          ) do |task, _supervisor, site|
            assert(site.ready?, 'expected site to be ready')
            collector = site.collector
            collector.use_task task
            collector.wait!
            got = collector.messages.map { |message| "#{message.direction}:#{message.type}" }
          end
          got
        rescue Async::TimeoutError
          raise "Did not collect #{length} messages within #{timeout}s"
        end

        def check_sequence_v311_to_v313(core_version)
          expected_version_messages = EXPECTED_VERSION_EXCHANGE_MESSAGES
          expected_watchdog_messages = EXPECTED_WATCHDOG_EXCHANGE_MESSAGES

          length = expected_version_messages.length + expected_watchdog_messages.length
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

        def expect_sequence_part!(got_part, expected:, forbidden:, context:)
          forbidden.each do |message|
            type = message.split(':').last
            assert(
              !got_part.include?(message),
              "#{type} not allowed during #{context}: #{got_part}"
            )
          end

          assert(
            got_part.tally == expected.tally,
            "Wrong #{context} part, must contain #{expected}, got #{got_part}"
          )
        end

        def check_sequence_v314_or_later(version)
          expected = EXPECTED_VERSION_EXCHANGE_MESSAGES + EXPECTED_WATCHDOG_EXCHANGE_MESSAGES
          got = get_connection_message version, expected.length
          assert(got == expected, "Expected connection sequence #{expected.inspect}, got #{got.inspect}")
        end

        def check_sequence_v330(version)
          expected = EXPECTED_VERSION_EXCHANGE_MESSAGES +
                     EXPECTED_WATCHDOG_EXCHANGE_MESSAGES +
                     EXPECTED_COMPONENT_LIST_MESSAGES
          got = get_connection_message version, expected.length
          assert(got == expected, "Expected connection sequence #{expected.inspect}, got #{got.inspect}")
        end

        def check_sequence(version)
          case version
          when '3.1.1', '3.1.2', '3.1.3'
            check_sequence_v311_to_v313 version
          when '3.1.4', '3.1.5', '3.2', '3.2.1', '3.2.2'
            check_sequence_v314_or_later version
          when '3.3.0'
            check_sequence_v330 version
          else
            raise "Unknown rsmp version #{version}"
          end
        end
      end
    end
  end
end
