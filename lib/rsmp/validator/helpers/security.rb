module Validator
  module Helpers
    # Helper methods for testing RSMP security code handling.
    module Security
      include Commands

      def wrong_security_code(site_proxy)
        log 'Try to force detector logic with wrong security code'
        command_list = RSMP::CommandList.new(:M0008, :setForceDetectorLogic,
                                             securityCode: '1111',
                                             status: 'True',
                                             mode: 'True').to_a
        component = Validator.get_config('components', 'detector_logic').keys[0]
        result = site_proxy.send_command component, command_list,
                                         within: Validator.get_config('timeouts', 'command_response')
        result[:collector].ok!
      end

      def require_security_codes
        return if Validator.config.dig 'secrets', 'security_codes'

        skip 'Security codes are not configured'
      end
    end
  end
end
