describe 'Site::Tlc::EmergencyRoutes' do
  include RSMP::Validator::Helpers::Status

  # Verify that current emergency route can be read with S0006.
  # Depreciated from 1.2, use S0035 instead.
  # 1. Given the site_proxy is connected.
  # 2. When we request S0006.
  # 3. Then we should receive a status response.
  it 'emergency route is read with S0006' do
    with_site(:connected, sxl: ['>=1.0.7', '<1.2']) do |site_proxy|
      site_proxy.request_status_and_collect({ S0006: %i[status emergencystage] },
                                            within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
    end
  end

  # Verify that current emergency routes can be read with S0035.
  # Requires core >= 3.2 since it uses the array data type.
  # 1. Given the site_proxy is connected.
  # 2. When we request S0035.
  # 3. Then we should receive a status response.
  it 'emergency route is read with S0035' do
    skip 'requires core >= 3.2' unless RSMP::Validator.core_matches?('>=3.2')
    with_site(:connected, sxl: '>=1.2') do |site_proxy|
      site_proxy.request_status_and_collect({ S0035: [:emergencyroutes] },
                                            within: RSMP::Validator.get_config('timeouts', 'status_response')).ok!
    end
  end

  # Verify that emergency routes can be activated with M0005.
  # S0006 should reflect the last route enabled/disabled.
  # 1. Given the site_proxy is connected.
  # 2. When we send M0005 to set emergency route.
  # 3. Then we should get a command responds confirming the change.
  it 'can be activated with M0005 and read with S0006' do
    skip 'requires sxl >= 1.0.7, < 1.2' unless RSMP::Validator.sxl_matches?(['>=1.0.7', '<1.2'])
    emergency_routes = RSMP::Validator.get_config('items', 'emergency_routes')
    skip('No emergency routes configured') if emergency_routes.nil? || emergency_routes.empty?

    def set_emergency_states(site_proxy, emergency_routes, state)
      timeout = RSMP::Validator.get_config('timeouts', 'command_response')
      emergency_routes.each do |emergency_route|
        site_proxy.tlc.set_emergency_route(route: emergency_route.to_s, active: state, within: timeout)
      end
      wait_for_status(site_proxy, "emergency route #{emergency_routes.last} to be enabled",
                      [
                        { 'sCI' => 'S0006', 'n' => 'status', 's' => (state ? 'True' : 'False') },
                        { 'sCI' => 'S0006', 'n' => 'emergencystage',
                          's' => (state ? emergency_routes.last.to_s : '0') }
                      ])
    end

    with_site(:connected) do |site_proxy|
      set_emergency_states(site_proxy, emergency_routes, false)
      begin
        set_emergency_states(site_proxy, emergency_routes, true)
      ensure
        set_emergency_states(site_proxy, emergency_routes, false)
      end
    end
  end

  # Verify that emergency routes can be activated with M0005.
  # S0035 should show all active routes.
  # 1. Given the site_proxy is connected.
  # 2. When we send M0005 to set emergency route.
  # 3. Then we should get a command responds confirming the change.
  # 4. When we request the current emergency routes with S035.
  # 5. Then we should receive the list of active routes.

  it 'emergency routes can be activated with M0005 and read with S0035' do
    skip 'requires core >= 3.2' unless RSMP::Validator.core_matches?('>=3.2')
    skip 'requires sxl >= 1.2' unless RSMP::Validator.sxl_matches?('>=1.2')

    emergency_routes = RSMP::Validator.get_config('items', 'emergency_routes')
    skip('No emergency routes configured') if emergency_routes.nil? || emergency_routes.empty?

    def enable_routes(site_proxy, emergency_routes)
      timeout = RSMP::Validator.get_config('timeouts', 'command_response')
      emergency_routes.each do |emergency_route|
        site_proxy.tlc.set_emergency_route(route: emergency_route.to_s, active: true, within: timeout)
      end
      routes = emergency_routes.map { |i| { 'id' => i.to_i } }
      wait_for_status(site_proxy, "emergency routes #{emergency_routes} to be enabled",
                      [{ 'sCI' => 'S0035', 'n' => 'emergencyroutes', 's' => routes }])
    end

    def disable_routes(site_proxy, emergency_routes, within:)
      emergency_routes.each do |emergency_route|
        site_proxy.tlc.set_emergency_route(route: emergency_route.to_s, active: false, within:)
      end
      routes = []
      wait_for_status(site_proxy, 'all emergency routes to be disabled',
                      [{ 'sCI' => 'S0035', 'n' => 'emergencyroutes', 's' => routes }])
    end

    with_site(:connected) do |site_proxy|
      timeout = RSMP::Validator.get_config('timeouts', 'command_response')
      disable_routes(site_proxy, emergency_routes, within: timeout)
      begin
        enable_routes(site_proxy, emergency_routes)
      ensure
        disable_routes(site_proxy, emergency_routes, within: timeout)
      end
    end
  end
end
