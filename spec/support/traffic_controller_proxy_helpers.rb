# Helper methods for interacting with TrafficControllerProxy-enabled sites
# Falls back to traditional helpers when TrafficControllerProxy is not available
module Validator::TrafficControllerProxyHelpers
  
  # Switch to a specified timeplan using TrafficControllerProxy if available,
  # otherwise fall back to traditional helper methods
  def switch_timeplan_with_proxy(site, plan)
    if site.is_a?(RSMP::TLC::TrafficControllerProxy)
      # Use TrafficControllerProxy methods
      security_code = Validator.get_config('secrets','security_codes',2)
      result = site.set_timeplan(plan, security_code: security_code, options: { collect!: {
        timeout: Validator.get_config('timeouts','command_response')
      } })
      
      # Wait for the timeplan to actually change
      wait_for_timeplan_change(site, plan)
    else
      # Fall back to traditional helpers
      switch_plan(plan)
    end
  end
  
  # Read current timeplan using TrafficControllerProxy if available,
  # otherwise fall back to traditional helper methods
  def read_current_timeplan_with_proxy(site)
    if site.is_a?(RSMP::TLC::TrafficControllerProxy)
      # Use TrafficControllerProxy methods
      result = site.fetch_signal_plan(options: { collect!: {
        timeout: Validator.get_config('timeouts','status_response')
      } })
      site.timeplan
    else
      # Fall back to traditional helpers
      read_current_plan(site)
    end
  end
  
  # Request timeplan status using TrafficControllerProxy if available,
  # otherwise fall back to traditional helper methods
  def request_timeplan_status_with_proxy(site, description = "current time plan")
    if site.is_a?(RSMP::TLC::TrafficControllerProxy)
      # Use TrafficControllerProxy methods
      if RSMP::Proxy.version_meets_requirement?(site.sxl_version, '>=1.1')
        result = site.fetch_signal_plan(options: { collect!: {
          timeout: Validator.get_config('timeouts','status_response')
        } })
      else
        # For older versions, only request status without source
        status_list = [{ "sCI" => "S0014", "n" => "status" }]
        result = site.request_status site.main.c_id, status_list, collect!: {
          timeout: Validator.get_config('timeouts','status_response')
        }
      end
      result
    else
      # Fall back to traditional helpers
      if RSMP::Proxy.version_meets_requirement?(site.sxl_version, '>=1.1')
        status_list = { S0014: [:status,:source] }
      else
        status_list = { S0014: [:status] }
      end
      request_status_and_confirm site, description, status_list
    end
  end
  
  private
  
  # Wait for the timeplan to change to the expected value
  def wait_for_timeplan_change(site, expected_plan)
    start_time = Time.now
    timeout = Validator.get_config('timeouts','command')
    
    loop do
      current_plan = site.timeplan
      if current_plan == expected_plan.to_i
        Validator::Log.log "Timeplan changed to #{expected_plan}"
        return
      end
      
      if Time.now - start_time > timeout
        raise RSMP::TimeoutError.new "Timeplan did not change to #{expected_plan} within #{timeout}s (current: #{current_plan})"
      end
      
      sleep 0.1
    end
  end
end