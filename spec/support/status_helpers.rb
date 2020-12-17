module StatusHelpers
  def unsubscribe_from_all
    @site.unsubscribe_to_status @component, [
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

  def subscribe status_list, update_rate: RSMP_CONFIG['status_update_rate']
    sub_list = status_list.map { |item| item.slice('sCI','n').merge 'uRt'=>update_rate.to_s }
    expect do
      @site.subscribe_to_status @component, sub_list
    end.to_not raise_error
  end

  def verify_status parent_task, description, status_list
    log_confirmation description do
      begin
        @site.wait_for_status_updates(parent_task,{
          component: @component,
          status_list: status_list,
          timeout: SUPERVISOR_CONFIG['status_update_timeout']
        }) do
          subscribe status_list
        end
      rescue Async::TimeoutError
        expect { raise "Did not receive status within #{SUPERVISOR_CONFIG['status_update_timeout']}s" }.not_to raise_error
      end
      unsubscribe_from_all
    end
  end

  def request_status_and_confirm description, status_list, component=MAIN_COMPONENT
    TestSite.connected do |task,supervisor,site|
      @site = site
      log_confirmation "request of #{description}" do
        begin
          site.fetch_status task,
                            component: component,
                            status_list: status_list, 
                            timeout: SUPERVISOR_CONFIG['status_response_timeout']
        end
      end
    end
  end
end