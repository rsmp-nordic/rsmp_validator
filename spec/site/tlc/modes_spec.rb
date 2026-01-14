# frozen_string_literal: true

RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::StatusHelpers
  include Validator::CommandHelpers

  describe 'Operational' do
    # Verify status S0020 control mode
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'control mode is read with S0020', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'control mode',
                                   { S0020: %i[controlmode intersection] }
      end
    end

    # Verify status S0005 traffic controller starting
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'startup status is read with S0005', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'traffic controller starting (true/false)',
                                   { S0005: [:status] }
      end
    end

    # Verify status S0005 traffic controller starting by intersection
    # statusByIntersection requires core >= 3.2, since it uses the array data type.
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'startup status is read with S0005', sxl: '>=1.2', core: '>=3.2' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'traffic controller starting (true/false)',
                                   { S0005: [:statusByIntersection] }
      end
    end

    # Verify status S0007 controller switched on (dark mode=off)
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'switched on is read with S0007', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        status_list = { S0007: %i[status intersection] }
        request_status_and_confirm site, 'controller switch on (dark mode=off)', status_list
      end
    end

    # Verify status S0007 controller switched on, source attribute
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'switched on is read with S0007', sxl: '>=1.1' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        status_list = { S0007: %i[status intersection source] }
        request_status_and_confirm site, 'controller switch on (dark mode=off)', status_list
      end
    end

    # Verify status S0008 manual control
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'manual control is read with S0008', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        status_list = if RSMP::Proxy.version_meets_requirement?(site.sxl_version, '>=1.1')
                        { S0008: %i[status intersection source] }
                      else
                        { S0008: %i[status intersection] }
                      end
        request_status_and_confirm site, 'manual control status', status_list
      end
    end

    # Verify status S0009 fixed time control
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'fixed time control is read with S0009', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        status_list = if RSMP::Proxy.version_meets_requirement?(site.sxl_version, '>=1.1')
                        { S0009: %i[status intersection source] }
                      else
                        { S0009: %i[status intersection] }
                      end
        request_status_and_confirm site, 'fixed time control status', status_list
      end
    end

    # Verify command M0007 fixed time control
    #
    # 1. Verify connection
    # 2. Send command to switch to fixed time = true
    # 3. Wait for status = true
    # 4. Send command to switch to fixed time = false
    # 5. Wait for status = false
    specify 'fixed time control can be activated with M0007', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        switch_fixed_time 'True'
        switch_fixed_time 'False'
      end
    end

    # Verify status S0010 isolated control
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'isolated control is read with S0010', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        status_list = if RSMP::Proxy.version_meets_requirement?(site.sxl_version, '>=1.1')
                        { S0010: %i[status intersection source] }
                      else
                        { S0010: %i[status intersection] }
                      end
        request_status_and_confirm site, 'isolated control status', status_list
      end
    end

    # Verify status S0032 coordinated control
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'coordinated control is read with S0032', sxl: '>=1.1' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        status_list = { S0032: %i[status intersection source] }
        request_status_and_confirm site, 'coordinated control status', status_list
      end
    end

    # Verify status S0011 yellow flash
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'yellow flash can be read with S0011', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        status_list = if RSMP::Proxy.version_meets_requirement?(site.sxl_version, '>=1.1')
                        { S0011: %i[status intersection source] }
                      else
                        { S0011: %i[status intersection] }
                      end
        request_status_and_confirm site, 'yellow flash status', status_list
      end
    end

    # Verify that we can activate yellow flash
    #
    # 1. Given the site is connected
    # 2. Send the control command to switch to Yellow flash
    # 3. Wait for status Yellow flash
    # 4. Send command to switch to normal control
    # 5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"
    specify 'yellow flash can be activated with M0001', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        switch_yellow_flash
        switch_normal_control
      end
    end

    # Verify that we can yellow flash causes all groups to go to state 'c'
    #
    # 1. Given the site is connected
    # 2. Send the control command to switch to Yellow flash
    # 3. Wait for all groups to go to group 'c'
    # 4. Send command to switch to normal control
    # 5. Wait for all groups to switch do something else that 'c'
    specify 'yellow flash affects all signal groups', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        timeout = Validator.get_config('timeouts', 'yellow_flash')

        switch_yellow_flash
        wait_for_groups 'c', timeout: timeout      # c mean s yellow flash

        switch_normal_control
        wait_for_groups '[^c]', timeout: timeout   # not c, ie. not yellow flash
      end
    end

    # Verify status S0012 all red
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'all red can be read with S0012', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        status_list = if RSMP::Proxy.version_meets_requirement?(site.sxl_version, '>=1.1')
                        { S0012: %i[status intersection source] }
                      else
                        { S0012: %i[status intersection] }
                      end
        request_status_and_confirm site, 'all-red status', status_list
      end
    end

    # Verify status S0013 police key
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'police key can be read with S0013', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'police key',
                                   { S0013: [:status] }
      end
    end

    # Verify that we can activate dark mode
    #
    # 1. Given the site is connected
    # 2. Send the control command to switch todarkmode
    # 3. Wait for status"Controller on" = false
    # 4. Send command to switch to normal control
    # 5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"
    specify 'dark mode can be activated with M0001', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        switch_dark_mode
        switch_normal_control
      end
    end

    # Verify that we can activate yellow flash and after 1 minute goes back to NormalControl
    #
    # 1. Given the site is connected
    # 2. Send the control command to switch to Normal Control, and wait for this
    # 2. Send the control command to switch to Yellow flash
    # 3. Wait for status Yellow flash
    # 5. Wait for automatic revert to Normal Control
    specify 'yellow flash be used with a timeout of one minute', sxl: '>=1.0.7', slow: true do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        switch_normal_control
        minutes = 1
        switch_yellow_flash timeout_minutes: minutes
        wait_normal_control timeout: (minutes * 60) + Validator.get_config('timeouts', 'functional_position')
      end
    end
  end
end
