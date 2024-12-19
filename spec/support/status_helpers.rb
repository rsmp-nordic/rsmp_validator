module Validator::StatusHelpers

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

  def unsubscribe_from_all
    @site.unsubscribe_to_status Validator.get_config('main_component'), [
      {'sCI'=>'S0015','n'=>'status'},
      {'sCI'=>'S0014','n'=>'status'},
      {'sCI'=>'S0011','n'=>'status'},
      {'sCI'=>'S0009','n'=>'status'},
      {'sCI'=>'S0007','n'=>'status'},
      {'sCI'=>'S0006','n'=>'status'},
      {'sCI'=>'S0006','n'=>'emergencystage'},
      {'sCI'=>'S0005','n'=>'status'},
      {'sCI'=>'S0003','n'=>'inputstatus'},
      {'sCI'=>'S0002','n'=>'detectorlogicstatus'},
      {'sCI'=>'S0001','n'=>'signalgroupstatus'},
      {'sCI'=>'S0001','n'=>'cyclecounter'},
      {'sCI'=>'S0001','n'=>'basecyclecounter'},
      {'sCI'=>'S0001','n'=>'stage'}
    ]
  end

  def verify_status parent_task, description, status_list
    log description
    @site.request_status Validator.get_config('main_component'), convert_status_list(status_list), collect!: {
      timeout: Validator.get_config('timeouts','status_update', assume: 0)
    }
  end

  def wait_for_status parent_task, description, status_list,
      update_rate: Validator.get_config('intervals','status_update', assume: 0),
      timeout: Validator.get_config('timeouts','command')
    update_rate = 0 unless update_rate
    log "Wait for #{description}"
    subscribe_list = convert_status_list(status_list).map { |item| item.merge 'uRt'=>update_rate.to_s }
    subscribe_list.map! { |item| item.merge!('sOc' => false) } if use_sOc?(@site)

    begin
      result = @site.subscribe_to_status Validator.get_config('main_component'), subscribe_list, collect!: {
        timeout: timeout
      }
    ensure
      unsubscribe_list = convert_status_list(status_list).map { |item| item.slice('sCI','n') }
      @site.unsubscribe_to_status Validator.get_config('main_component'), unsubscribe_list
    end
  end

  def wait_for_groups state, timeout:
    regex = /^#{state}+$/
    wait_for_status(@task,
      "Wait for all groups to go to yellow flash",
      [{'sCI'=>'S0001','n'=>'signalgroupstatus','s'=>regex}],
      update_rate: 0,
      timeout: timeout
    )
  end

  def request_status_and_confirm site, description, status_list, component=Validator.get_config('main_component')
    @site = site
    log "Read #{description}"
    result = site.request_status component, convert_status_list(status_list), collect!: {
      timeout: Validator.get_config('timeouts','status_response'),
    }
  end

  # Should the sOc attribute be used?
  # It should if the core version is 3.1.5 or higher.
  def use_sOc? site
    RSMP::Proxy.version_meets_requirement? site.core_version, '>=3.1.5'
  end

  # Use S0028 to read current cycle time lengths.
  # returns a map of signal program nr => cycle time in seconds
  def read_cycle_times(site, description='cycle times')
    result = request_status_and_confirm site, description,
      { S0028: [:status] }
    result[:collector].messages.first.attributes['sS'].first['s'].split(',').map do |time|
      program_time = time.split('-').map {|v| v.to_i}
    end.to_h
  end

  # Use S0014 to read current plan.
  # returns a map of signal program nr => cycle time in seconds
  def read_current_plan(site, description='current plan')
    result = request_status_and_confirm site, description,
      { S0014: [:status] }
    result[:collector].messages.first.attributes['sS'].first['s'].to_i
  end
end