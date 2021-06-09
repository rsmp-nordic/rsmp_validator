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

  def unsubscribe_from_all
    @site.unsubscribe_to_status TestSite.config['main_component'], [
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
    log_confirmation description do
      message, result = @site.request_status TestSite.config['main_component'], convert_status_list(status_list), collect: {
        timeout: TestSite.config['timeouts']['status_update']
      }
    end
  end

  def wait_for_status parent_task, description, status_list, update_rate: TestSite.config['intervals']['status_update']
    update_rate = 0 unless update_rate
    log_confirmation description do
      subscribe_list = convert_status_list(status_list).map { |item| item.merge 'uRt'=>update_rate.to_s }
      begin
        message, result = @site.subscribe_to_status TestSite.config['main_component'], subscribe_list, collect: {
          timeout: TestSite.config['timeouts']['command']
        }
      ensure
        unsubscribe_list = convert_status_list(status_list).map { |item| item.slice('sCI','n') }
        @site.unsubscribe_to_status TestSite.config['main_component'], unsubscribe_list
      end
    end
  end

  def request_status_and_confirm description, status_list, component=TestSite.config['main_component']
    TestSite.connected do |task,supervisor,site|
      @site = site
      log_confirmation "request of #{description}" do
        site.request_status component, convert_status_list(status_list), collect: {
          timeout: TestSite.config['timeouts']['status_response']
        }
      end
    end
  end
end