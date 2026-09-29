describe 'Site::Tlc::Subscribe' do
  # Check that we can *subscribe* to status messages.
  # The test subscribes to S0001 (signal group status), because
  # it will usually change once per second, but otherwise the choice
  # is arbitrary as we simply want to check that
  # the subscription mechanism works.
  #
  # 1. Given the site_proxy is connected
  # 2. When we subscribe to S0001
  # 3. Then we should receive a status update
  # 4. Finally we unsubscribe from S0001

  it 'can be turned on and off for S0001' do
    with_site(:connected) do |site_proxy|
      log 'Subscribe to status and wait for update'
      component = RSMP::Validator.get_config('main_component')

      status_list = [{ 'sCI' => 'S0001', 'n' => 'signalgroupstatus', 'uRt' => '1' }]
      status_list.map! { |item| item.merge!('sOc' => true) } if site_proxy.tlc.use_soc?

      site_proxy.subscribe_to_status_and_collect(status_list,
                                                 component: component,
                                                 within: RSMP::Validator.get_config('timeouts', 'status_update')).value!
    ensure
      unsubscribe_list = status_list.map { |item| item.slice('sCI', 'n') }
      site_proxy.unsubscribe_to_status! unsubscribe_list, component: component
    end
  end

  # Check that we can change the update rate interval while status subscription is active.
  # The test subscribes to S0001 'cyclecounter' attribute with an initial update rate of 60s,
  # then changes the update rate to 1s and verifies the new rate is in effect.
  #
  # 1. Given the site_proxy is connected
  # 2. When we subscribe to S0001 'cyclecounter' with update rate 60s
  # 3. And we change the update rate to 1s
  # 4. Then we should receive two immediate updates and one periodic update within 2s
  # 5. Finally we unsubscribe from S0001

  it 'can change interval during active subscription' do
    with_site(:connected) do |site_proxy|
      component = RSMP::Validator.get_config('main_component')
      matcher = RSMP::StatusMatcher.new('sCI' => 'S0001', 'n' => 'cyclecounter')

      # start collecting matching status updates
      collector = RSMP::Collector.new(
        site_proxy,
        filter: RSMP::Filter.new(type: 'StatusUpdate', component: component, ingoing: true, outgoing: false),
        num: 3,
        timeout: 2
      )
      collector.start do |message|
        :keep if message.attributes.fetch('sS', []).any? { |item| matcher.match(item) }
      end

      log 'Subscribe to S0001 cyclecounter with 60s update rate'
      status_list = [{ 'sCI' => 'S0001', 'n' => 'cyclecounter', 'uRt' => '60' }]
      status_list.each { |item| item['sOc'] = false } if site_proxy.tlc.use_soc?
      site_proxy.subscribe_to_status! status_list, component: component

      log 'Change update rate to 1s and wait for three updates within 2s'
      status_list.first['uRt'] = '1'
      site_proxy.subscribe_to_status! status_list, component: component

      expect(collector.wait).to be(:success?)
      log 'Received three updates within 2s, confirming periodic updates at the new rate'
    ensure
      collector&.stop
      # Clean up subscription
      unsubscribe_list = [{ 'sCI' => 'S0001', 'n' => 'cyclecounter' }]
      site_proxy.unsubscribe_to_status! unsubscribe_list, component: component
    end
  end
end
