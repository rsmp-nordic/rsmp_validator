module StatusHelpers

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
  def convert_status_list list
    return list.clone if list.is_a? Array
    list.map do |status_code_id,names|
      names.map do |name|
        { 'sCI' => status_code_id.to_s, 'n' => name.to_s }
      end
    end.flatten
  end

  def verify_status parent_task, description, status_list
    log_confirmation description do
      message, result = @site.request_status @component, convert_status_list(status_list), collect: {
        timeout: SUPERVISOR_CONFIG['status_update_timeout']
      }
    end
  end

  def wait_for_status parent_task, description, status_list, update_rate: RSMP_CONFIG['status_update_rate']
    log_confirmation description do
      subscribe_list = convert_status_list(status_list).map { |item| item.merge 'uRt'=>update_rate.to_s }
      begin
        message, result = @site.subscribe_to_status @component, subscribe_list, collect: {
          timeout: RSMP_CONFIG['command_timeout']
        }
      ensure
        @site.unsubscribe_to_status @component, status_list
      end
    end
  end

  def request_status_and_confirm description, status_list, component=MAIN_COMPONENT
    TestSite.connected do |task,supervisor,site|
      @site = site
      log_confirmation "request of #{description}" do
        site.request_status component, convert_status_list(status_list), collect: {
          timeout: SUPERVISOR_CONFIG['status_response_timeout']
        }
      end
    end
  end
end