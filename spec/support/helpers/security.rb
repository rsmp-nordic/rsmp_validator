module Validator
  module Helpers
    module Security
      include Commands

      def wrong_security_code(site)
        log 'Try to force detector logic with wrong security code'
        command_list = build_command_list :M0008, :setForceDetectorLogic, {
          securityCode: '1111',
          status: 'True',
          mode: 'True'
        }
        component = Validator.get_config('components', 'detector_logic').keys[0]
        site.send_command component, command_list, collect!: {
          timeout: Validator.get_config('timeouts', 'command_response')
        }
      end

      def require_security_codes
        return if Validator.config.dig 'secrets', 'security_codes'

        skip 'Security codes are not configured'
      end
    end
  end
end
