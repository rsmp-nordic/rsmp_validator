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

      def with_site(state, sxl: nil, core: nil, **opts, &block)
        raise ArgumentError, "Unknown state #{state.inspect}, must be one of #{VALID_STATES}" unless VALID_STATES.include?(state)
        skip "requires sxl #{sxl}" unless sxl.nil? || Validator.sxl_matches?(sxl)
        skip "requires core #{core}" unless core.nil? || Validator.core_matches?(core)
        if state == :disconnected
          Validator::SiteTester.disconnected { block.call }
        else
          Validator::SiteTester.public_send(state, **opts) do |_task, _node, proxy|
            block.call(proxy)
          end
        end
      end

      def with_supervisor(state, sxl: nil, core: nil, **opts, &block)
        raise ArgumentError, "Unknown state #{state.inspect}, must be one of #{VALID_STATES}" unless VALID_STATES.include?(state)
        skip "requires sxl #{sxl}" unless sxl.nil? || Validator.sxl_matches?(sxl)
        skip "requires core #{core}" unless core.nil? || Validator.core_matches?(core)
        if state == :disconnected
          Validator::SupervisorTester.disconnected { block.call }
        else
          Validator::SupervisorTester.public_send(state, **opts) do |_task, _node, proxy|
            block.call(proxy)
          end
        end
      end
    end
  end
end
