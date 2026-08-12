module RSMP
  module Validator
    module Helpers
      # Helpers for connecting to a site or supervisor in tests, with optional
      # version-based skipping via sxl: and core: keyword arguments.
      #
      # with_site(:connected, sxl: '>=1.2') do |supervisor, site_proxy|
      #   ...
      # end
      #
      # with_supervisor(:connected, core: '>=3.2') do |site, supervisor_proxy|
      #   ...
      # end
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

        # Reports a recognizable transport-level failure without presenting it as
        # an uncaught validator exception.
        class ConnectionLost < StandardError
          def initialize(original)
            super("RSMP connection was lost while the test was running: #{original.message}")
            set_backtrace(original.backtrace)
          end
        end

        # A malformed secure frame is still a test error, but identifying it as
        # a protocol failure makes the cause and severity explicit.
        class SecureProtocolFailure < StandardError
          def initialize(original)
            super("Secure RSMP protocol failure while the test was running: #{original.message}")
            set_backtrace(original.backtrace)
          end
        end

        def with_site(state, sxl: nil, core: nil, **opts, &block)
          validate_state!(state)
          check_version_requirements(sxl, core)
          if state == :disconnected
            RSMP::Validator::SiteTester.disconnected { block.call }
          else
            RSMP::Validator::SiteTester.public_send(state, **opts) do |_task, _node, proxy|
              block.call(proxy)
            rescue RSMP::TimeoutError => e
              @__assertions__.assert false, e.message
            rescue StandardError => e
              report_exception(e)
            end
          end
        end

        def with_supervisor(state, sxl: nil, core: nil, **opts, &block)
          validate_state!(state)
          check_version_requirements(sxl, core)
          if state == :disconnected
            RSMP::Validator::SupervisorTester.disconnected { block.call }
          else
            RSMP::Validator::SupervisorTester.public_send(state, **opts) do |_task, _node, proxy|
              block.call(proxy)
            rescue RSMP::TimeoutError => e
              @__assertions__.assert false, e.message
            rescue StandardError => e
              report_exception(e)
            end
          end
        end

        private

        def report_exception(error)
          wrapped = if secure_protocol_failure?(error)
                      SecureProtocolFailure.new(error)
                    elsif connection_lost?(error)
                      ConnectionLost.new(error)
                    else
                      UncaughtException.new(error)
                    end
          @__assertions__.error!(wrapped)
        end

        def secure_protocol_failure?(error)
          defined?(RSMP::Secure::FrameError) && error.is_a?(RSMP::Secure::FrameError)
        end

        def connection_lost?(error)
          return true if error.is_a?(RSMP::NotReady) || error.is_a?(RSMP::DisconnectError)
          return true if connection_system_error?(error)
          return error.message == 'Secure RSMP peer closed connection' if error.is_a?(EOFError)
          return false unless error.is_a?(IOError)

          error.message == 'Secure RSMP transport is closed' ||
            error.message.match?(/\ACannot send .+: connection (?:is|transport is) /)
        end

        def connection_system_error?(error)
          return false unless error.is_a?(SystemCallError)

          %w[ECONNABORTED ECONNREFUSED ECONNRESET ENOTCONN EPIPE ETIMEDOUT].include?(
            error.class.name.delete_prefix('Errno::')
          )
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
