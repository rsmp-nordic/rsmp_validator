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
    @site.unsubscribe_to_status Validator.config['main_component'], [
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
    @site.request_status Validator.config['main_component'], convert_status_list(status_list), collect!: {
      timeout: Validator.config['timeouts']['status_update']
    }
  end

  def wait_for_status parent_task, description, status_list,
      update_rate: Validator.config['intervals']['status_update'],
      timeout: Validator.config['timeouts']['command']
    update_rate = 0 unless update_rate
    log "Wait for #{description}"
    subscribe_list = convert_status_list(status_list).map { |item| item.merge 'uRt'=>update_rate.to_s }
    subscribe_list.map! { |item| item.merge!('sOc' => 'False') } if use_sOc?(@site)

    begin
      result = @site.subscribe_to_status Validator.config['main_component'], subscribe_list, collect!: {
        timeout: timeout
      }
    ensure
      unsubscribe_list = convert_status_list(status_list).map { |item| item.slice('sCI','n') }
      @site.unsubscribe_to_status Validator.config['main_component'], unsubscribe_list
    end
  end

  def wait_for_groups state, timeout:
    timeout = 10
    regex = /^#{state}+$/
    wait_for_status(@task,
      "Wait for all groups to go to yellow flash",
      [{'sCI'=>'S0001','n'=>'signalgroupstatus','s'=>regex}],
      update_rate: 0,
      timeout: timeout
    )
  end

  def request_status_and_confirm description, status_list, component=Validator.config['main_component']
    Validator::Site.connected do |task,supervisor,site|
      @site = site
      log "Read #{description}"
      result = site.request_status component, convert_status_list(status_list), collect!: {
        timeout: Validator.config['timeouts']['status_response'],
      }
    end
  end

  # Check if the core version of a site proxy satisfies
  # a version string, e.g. ">=3.1.5".
  # Uses Gem classes to perform action checks, although this
  # has nothing to do with gems.
  def core_version_satisfies? site, condition
    core_version = Gem::Version.new(site.core_version)
    Gem::Requirement.new(condition).satisfied_by?(core_version)
  end

  # Should the sOc attribute be used?
  # It should if the core version is 3.1.5 or higher.
  def use_sOc? site
    core_version_satisfies? site, '>=3.1.5'
  end

end