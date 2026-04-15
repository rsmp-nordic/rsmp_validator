module Validator
  module Helpers
    # Helper methods for sending RSMP commands during tests.
    module Commands
      def send_command_and_confirm(site_proxy, command_list, message,
                                   component = Validator.get_config('main_component'))
        log message
        result = site_proxy.send_command component, command_list,
                                         within: Validator.get_config('timeouts', 'command_response')
        result[:collector].ok!
      end
    end
  end
end
