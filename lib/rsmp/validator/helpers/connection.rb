require_relative '../missing_configuration'
require_relative '../scenario'

module RSMP
  module Validator
    module Helpers
      # Helpers for connecting to a site or supervisor in tests, with optional
      # version-based skipping via sxl: and core: keyword arguments.
      #
      # with_site(:connected, sxl: '>=1.2.0') do |site_proxy|
      #   ...
      # end
      #
      # with_supervisor(:connected, core: '>=3.2.0') do |supervisor_proxy|
      #   ...
      # end
      #
      # with_scenario(proxy, id) checks test_scenarios and collects messages for
      # the duration of its block. The test decides when to send the hint.
      module Connection
        VALID_STATES = %i[connected reconnected isolated disconnected].freeze

        # Wraps an uncaught exception from a test block, preserving the original
        # class name, message, and backtrace for clearer test failure output.
        class UncaughtException < StandardError
          def initialize(original)
            super("#{original.class}: #{original.message}")
            set_backtrace(original.backtrace)
          end
        end

        def with_site(state, sxl: nil, core: nil, **opts, &block)
          validate_state!(state)
          check_version_requirements(sxl, core)
          if state == :disconnected
            RSMP::Validator::SiteTester.disconnected { run_test(&block) }
          else
            RSMP::Validator::SiteTester.public_send(state, **opts) do |_task, _node, proxy|
              run_test { block.call(proxy) }
            end
          end
        end

        def with_supervisor(state, sxl: nil, core: nil, **opts, &block)
          validate_state!(state)
          check_version_requirements(sxl, core)
          if state == :disconnected
            RSMP::Validator::SupervisorTester.disconnected { run_test(&block) }
          else
            RSMP::Validator::SupervisorTester.public_send(state, **opts) do |_task, _node, proxy|
              run_test { block.call(proxy) }
            end
          end
        end

        def with_scenario(proxy, id)
          skip 'Supervisor test scenarios are disabled' unless RSMP::Validator.config['test_scenarios'] == true

          scenario = Scenario.new(proxy, id)
          scenario.collect { yield scenario }
        end

        private

        def run_test
          yield
        rescue MissingConfiguration => e
          error_test e
        rescue RSMP::OperationError => e
          @__assertions__.assert false, e.failure.message
          throw :rsmp_validator_test_failure
        rescue StandardError => e
          error_test UncaughtException.new(e)
        end

        def error_test(error)
          @__assertions__.error! error
          throw :rsmp_validator_test_failure
        end

        def validate_state!(state)
          return if VALID_STATES.include?(state)

          raise ArgumentError, "Unknown state #{state.inspect}, must be one of #{VALID_STATES}"
        end

        def check_version_requirements(sxl, core)
          skip "requires sxl #{sxl}" unless sxl.nil? || RSMP::Validator.sxl_matches?(sxl)
          skip "requires core #{core}" unless core.nil? || RSMP::Validator.core_matches?(core)
        end
      end
    end
  end
end
