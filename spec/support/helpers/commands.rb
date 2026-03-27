module Validator
  module Helpers
    module Commands
      # Send an RSMP command and wait for confirmation response
      def send_command_and_confirm(site, command_list, message,
                                   component = Validator.get_config('main_component'))
        log message
        site.send_command component, command_list, collect!: {
          timeout: Validator.get_config('timeouts', 'command_response')
        }
      end

      # Build a RSMP command value list from a hash
      # @param command_code_id [Symbol] the command code identifier (e.g. :M0001)
      # @param command_name [Symbol] the command name (e.g. :setValue)
      # @param values [Hash] key-value pairs for command parameters
      # @return [Array] formatted command list for RSMP
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
