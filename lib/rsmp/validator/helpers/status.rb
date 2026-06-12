module RSMP
  module Validator
    module Helpers
      # Helper methods for requesting and subscribing to RSMP status values.
      module Status
        def wait_for_status(site_proxy, description, status_list, **options)
          update_rate = options.fetch(:update_rate, 0)
          timeout = options.fetch(:timeout, RSMP::Validator.get_config('timeouts', 'command'))
          component_id = options.fetch(:component_id, RSMP::Validator.get_config('main_component'))
          log "Wait for #{description}"
          site_proxy.tlc.wait_for_status(
            description,
            RSMP::StatusList.new(status_list).to_a,
            update_rate: update_rate,
            timeout: timeout,
            component_id: component_id
          )
        end
      end
    end
  end
end
