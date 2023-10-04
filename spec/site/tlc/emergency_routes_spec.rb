RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::CommandHelpers
  include Validator::StatusHelpers

  describe "Emergency Route" do

    # Verify that current emergency route can be read with S0006.
    # Depreciated from 1.2, use S0035 instead.
    # 1. Given the site is connected.
    # 2. When we request S0006.
    # 3. Then we should receive a status response.
    specify 'emergency route is read with S0006', sxl: ['>=1.0.7','<1.2'] do |example|
      Validator::Site.connected do |task,supervisor,site|
        request_status_and_confirm site, "emergency route status",
          { S0006: [:status,:emergencystage] }
      end
    end

    # Verify that current emergency routes can be read with S0035.
    # 1. Given the site is connected.
    # 2. When we request S0035.
    # 3. Then we should receive a status response.
    specify 'emergency route is read with S0035', sxl: '>=1.2' do |example|
      Validator::Site.connected do |task,supervisor,site|
        request_status_and_confirm site, "emergency route status",
          { S0035: [:emergencyroutes] }
      end
    end

    # Verify that emergency routes can be activated with M0005.
    # S0006 should reflect the last route enabled/disabled.
    # 1. Given the site is connected.
    # 2. When we send M0005 to set emergency route.
    # 3. Then we should get a command responds confirming the change.
    it 'can be activated with M0005 and read with S0006', sxl: ['>=1.0.7','<1.2'] do |example|
      emergency_routes = Validator.config['items']['emergency_routes']
      skip("No emergency routes configured") if emergency_routes.nil? || emergency_routes.empty?

      def set_and_check_emergecy_states task, emergency_routes, state
        emergency_routes.each { |emergency_route| set_emergency_route emergency_route.to_s, state }
        wait_for_status(task, "emergency route #{emergency_routes.last} to be enabled",
          [
            {'sCI'=>'S0006','n'=>'status','s'=>(state ? 'True' : 'False')},
            {'sCI'=>'S0006','n'=>'emergencystage','s'=>emergency_routes.last.to_s}
          ]
        )
      end

      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        set_and_check_emergecy_states task, emergency_routes, false
        begin
          set_and_check_emergecy_states task, emergency_routes, true
        ensure
          set_and_check_emergecy_states task, emergency_routes, false
        end
      end
    end

    # Verify that emergency routes can be activated with M0005.
    # S0035 should show all active routes.
    # 1. Given the site is connected.
    # 2. When we send M0005 to set emergency route.
    # 3. Then we should get a command responds confirming the change.
    # 4. When we request the current emergency routes with S035.
    # 5. Then we should receive the list of active routes.

    specify 'emergency route is read with S0035', sxl: '>=1.2' do |example|
      def enable_routes task, emergency_routes
        emergency_routes.each { |emergency_route| set_emergency_route emergency_route.to_s, true }
        routes = emergency_routes.map {|i| {'id'=>i.to_s} }
        wait_for_status(task, "emergency routes #{emergency_routes.to_s} to be enabled",
          [ {'sCI'=>'S0035','n'=>'emergencyroutes','s'=>routes} ]
        )
      end

      def disable_routes task, emergency_routes
        emergency_routes.each { |emergency_route| set_emergency_route emergency_route.to_s, false }
        routes = []
        wait_for_status(task, "emergency routes #{emergency_routes.to_s} to be disabled",
          [ {'sCI'=>'S0035','n'=>'emergencyroutes','s'=>routes} ]
        )
      end

      emergency_routes = Validator.config['items']['emergency_routes']
      skip("No emergency routes configured") if emergency_routes.nil? || emergency_routes.empty?

      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        disable_routes task, emergency_routes
        begin
          enable_routes task, emergency_routes
        ensure
          disable_routes task, emergency_routes
        end
      end
    end

  end
end
