module Validator
  module Helpers
    # Helper methods for sending RSMP commands during tests.
    module Commands
      def send_command_and_confirm(site_proxy, command_list, message,
                                   component = Validator.get_config('main_component'))
        log message
        site_proxy.send_command component, command_list, collect!: {
          timeout: Validator.get_config('timeouts', 'command_response')
        }
      end

      def build_command_list(command_code_id, command_name, values)
        values.compact.to_a.map do |n, v|
          {
            'cCI' => command_code_id.to_s,
            'cO' => command_name.to_s,
            'n' => n.to_s,
            'v' => v.to_s
          }
        end
      end
    end
  end
end
