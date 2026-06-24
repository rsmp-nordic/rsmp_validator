describe 'Site::Core' do
  describe 'Message Buffer' do
    def buffered_status_list(site_proxy)
      status_list = [{ 'sCI' => 'S0001', 'n' => 'signalgroupstatus', 'uRt' => '1' }]
      status_list.map! { |item| item.merge('sOc' => true) } if site_proxy.tlc.use_soc?
      status_list
    end

    def buffered_status_timeout
      RSMP::Validator.get_config('timeouts', 'ready') +
        RSMP::Validator.get_config('timeouts', 'status_update') + 1
    end

    def subscribe_buffered_status(component)
      with_site(:connected, core: '>=3.1.4') do |site_proxy|
        status_list = buffered_status_list(site_proxy)
        site_proxy.subscribe_to_status_and_collect(
          status_list,
          component: component,
          within: RSMP::Validator.get_config('timeouts', 'status_update')
        ).ok!
        status_list
      end
    end

    def simulate_status_buffer_disruption
      RSMP::Validator::SiteTester.instance.stop 'Simulating communication disruption'
      Async::Task.current.sleep 1.5
      Time.now.utc
    end

    def collect_status_after_reconnect(component, status_list)
      with_site(:connected,
                core: '>=3.1.4',
                'collect' => {
                  filter: RSMP::Filter.new(type: 'StatusUpdate',
                                           component: component,
                                           ingoing: true,
                                           outgoing: false),
                  timeout: buffered_status_timeout,
                  num: 1,
                  ingoing: true
                }) do |site_proxy|
        collector = site_proxy.collector
        collector.use_task Async::Task.current
        messages = collector.wait!
        update = messages.first

        unsubscribe_list = status_list.map { |item| item.slice('sCI', 'n') }
        site_proxy.unsubscribe_to_status unsubscribe_list, component: component
        update
      end
    end

    def collect_buffered_status_after_disruption
      collect_buffered_status_after_disruption_with_timing[:update]
    end

    def collect_buffered_status_after_disruption_with_timing
      component = RSMP::Validator.get_config('main_component')
      status_list = subscribe_buffered_status component
      reconnect_started_at = simulate_status_buffer_disruption
      update = collect_status_after_reconnect component, status_list
      { update: update, reconnect_started_at: reconnect_started_at }
    end

    # Verify that a site sends buffered status messages after communication is restored.
    #
    # 1. Given the site is connected and a status subscription is active
    # 2. When communication is disrupted long enough for a status update to be due
    # 3. And communication is restored
    # 4. Then the site should send the buffered status update
    it 'sends buffered status messages after communication is restored' do
      skip 'requires core >= 3.1.4' unless RSMP::Validator.core_matches?('>=3.1.4')

      update = collect_buffered_status_after_disruption

      expect(update).to be_a(RSMP::StatusUpdate)
      assert(!update.attributes['sS'].empty?, 'expected buffered status update to include status values')
    end

    # Verify that buffered status messages use quality "old" for core versions
    # where the core spec requires it.
    #
    # 1. Given the site is connected using core 3.2 or later
    # 2. And a status subscription is active
    # 3. When communication is disrupted and later restored
    # 4. Then buffered status values should have q=old
    it 'marks buffered status values as old for rsmp 3.2 and later' do
      skip 'requires core >= 3.2' unless RSMP::Validator.core_matches?('>=3.2')

      update = collect_buffered_status_after_disruption

      expect(update.attributes['sS'].map { |status| status['q'] }.uniq).to be == ['old']
    end

    # Verify that buffered status timestamps reflect when the status data was
    # generated, not when the buffered message was sent after reconnect.
    #
    # 1. Given the site is connected and a status subscription is active
    # 2. When communication is disrupted long enough for a status update to be due
    # 3. And communication is restored
    # 4. Then the buffered status timestamp should be older than the reconnect
    it 'preserves buffered status timestamps from before reconnect' do
      skip 'requires core >= 3.1.4' unless RSMP::Validator.core_matches?('>=3.1.4')

      result = collect_buffered_status_after_disruption_with_timing
      status_time = Time.parse(result[:update].attributes['sTs'])

      assert(status_time < result[:reconnect_started_at],
             "expected buffered status timestamp #{status_time} to be before reconnect " \
             "#{result[:reconnect_started_at]}")
    end
  end
end
