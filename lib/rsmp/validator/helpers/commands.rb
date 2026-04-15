module Validator
  module Helpers
    # Helper methods for sending RSMP commands during tests.
    module Commands
      def send_command_and_confirm(site_proxy, command_list, message,
                                   component = Validator.get_config('main_component'))
        log message
        timeout = Validator.get_config('timeouts', 'command_response')
        site_proxy.send_command_and_collect(command_list, component: component, within: timeout).ok!
      end
    end
  end
end
