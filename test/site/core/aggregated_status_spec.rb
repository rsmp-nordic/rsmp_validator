describe 'Site::Core' do
  describe 'Aggregated Status' do
    # Verify that the controller responds to an aggregated status request.
    #
    # 1. Given the site is connected
    # 2. When we request aggregated status
    # 3. Then we should receive an aggregated status
    it 'can be requested' do
      with_site(:connected, core: '>=3.1.5') do |site_proxy|
        log 'Request aggregated status'
        site_proxy.request_aggregated_status_and_collect(
          RSMP::Validator.get_config('main_component'),
          within: RSMP::Validator.get_config('timeouts', 'status_response')
        ).value!
      end
    end

    # Verify that aggregated status uses null for unused attributes, from SXL 1.1.0 and core before 3.3.0.
    # For SXL versions before 1.1.0 empty strings "" is also allowed.
    #
    # 1. Given the is reconnected
    # 2. When we receive an aggregated status
    # 3. Then fP and fS should be null
    it 'uses null for functional position/state' do
      with_site(:isolated, sxl: '>=1.1.0', core: '<3.3.0',
                           'collect' => {
                             filter: RSMP::Filter.new(type: 'AggregatedStatus', ingoing: true, outgoing: false),
                             timeout: RSMP::Validator.get_config('timeouts', 'ready'),
                             num: 1
                           }) do |site_proxy|
        collector = site_proxy.collector
        aggregated_status = collector.wait!.first

        expect(aggregated_status).to be_a(RSMP::AggregatedStatus)
        expect(aggregated_status.attribute('fP')).to be_nil
        expect(aggregated_status.attribute('fS')).to be_nil
      end
    end

    # Verify that aggregated status omits unused attributes from core  3.3.0.
    #
    # 1. Given the is reconnected
    # 2. When we receive an aggregated status
    # 3. Then fP and fS should be omitted
    it 'omits functional position/state' do
      with_site(:isolated, core: '>=3.3.0',
                           'collect' => {
                             filter: RSMP::Filter.new(type: 'AggregatedStatus', ingoing: true, outgoing: false),
                             timeout: RSMP::Validator.get_config('timeouts', 'ready'),
                             num: 1
                           }) do |site_proxy|
        collector = site_proxy.collector
        aggregated_status = collector.wait!.first

        expect(aggregated_status).to be_a(RSMP::AggregatedStatus)
        expect(aggregated_status.attributes.key?('fP')).to be == false
        expect(aggregated_status.attributes.key?('fS')).to be == false
      end
    end
  end
end
