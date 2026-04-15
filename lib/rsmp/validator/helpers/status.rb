module Validator
  module Helpers
    # Helper methods for requesting and subscribing to RSMP status values.
    module Status
      def wait_for_status(site_proxy, description, status_list, **options)
        update_rate = options.fetch(:update_rate, 0)
        timeout = options.fetch(:timeout, Validator.get_config('timeouts', 'command'))
        component_id = options.fetch(:component_id, Validator.get_config('main_component'))
        log "Wait for #{description}"
        site_proxy.wait_for_status(
          description,
          RSMP::StatusList.new(status_list).to_a,
          update_rate: update_rate,
          timeout: timeout,
          component_id: component_id
        )
      end

      def request_status_and_confirm(site_proxy, description, status_list,
                                     component = Validator.get_config('main_component'))
        log "Read #{description}"
        site_proxy.request_status RSMP::StatusList.new(status_list),
                                  component: component,
                                  within: Validator.get_config('timeouts', 'status_response')
      end
    end
  end
end
