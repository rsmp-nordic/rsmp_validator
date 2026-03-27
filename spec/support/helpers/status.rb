module Validator
  module Helpers
    module Status
      # Convert from a hash:
      # {:S0001=>[:signalgroupstatus, :cyclecounter, :basecyclecounter, :stage]}
      #
      # to an rsmp-style list:
      # [
      #   {"sCI"=>"S0001", "n"=>"signalgroupstatus"},
      #   {"sCI"=>"S0001", "n"=>"cyclecounter"},
      #   {"sCI"=>"S0001", "n"=>"basecyclecounter"},
      #   {"sCI"=>"S0001", "n"=>"stage"}
      # ]
      #
      # If the input is already an array, just return it
      def convert_status_list(list)
        return list.clone if list.is_a? Array

        list.map do |status_code_id, names|
          names.map do |name|
            { 'sCI' => status_code_id.to_s, 'n' => name.to_s }
          end
        end.flatten
      end

      def wait_for_status(site, description, status_list, **options)
        update_rate = options.fetch(:update_rate, 0)
        timeout = options.fetch(:timeout, Validator.get_config('timeouts', 'command'))
        component_id = options.fetch(:component_id, Validator.get_config('main_component'))
        log "Wait for #{description}"
        site.wait_for_status(
          description,
          convert_status_list(status_list),
          update_rate: update_rate,
          timeout: timeout,
          component_id: component_id
        )
      end

      def request_status_and_confirm(site, description, status_list, component = Validator.get_config('main_component'))
        log "Read #{description}"
        site.request_status component, convert_status_list(status_list), collect!: {
          timeout: Validator.get_config('timeouts', 'status_response')
        }
      end
    end
  end
end
