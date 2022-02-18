RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::StatusHelpers
  include Validator::CommandHelpers

  describe "Operational" do
    # Verify status S0020 control mode
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'control mode is read with S0020', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "control mode",
        { S0020: [:controlmode,:intersection] }
    end

    # Verify status S0005 traffic controller starting
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'startup status is read with S0005', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "traffic controller starting (true/false)",
        { S0005: [:status] }
    end

    # Verify status S0006 emergency stage
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'emergency stage is read with S0006', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "emergency stage status",
        { S0006: [:status,:emergencystage] }
    end

    # Verify status S0007 controller switched on (dark mode=off)
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'switched on is read with S0007', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "controller switch on (dark mode=off)",
        { S0007: [:status,:intersection] }
    end

    # Verify status S0008 manual control
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'manual control is read with S0008', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "manual control status",
        { S0008: [:status,:intersection] }
    end

    # Verify status S0009 fixed time control
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'fixed time control is read with S0009', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "fixed time control status",
        { S0009: [:status,:intersection] }
    end

    # 1. Verify connection
    #
    # 2. Send the control command to switch to  fixed time= true
    # 3. Wait for status = true
    # 4. Send control command to switch "fixed time"= true
    # 5. Wait for status = false
    specify 'fixed time control can be activated with M0007', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
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
    specify 'isolated control is read with S0010', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "isolated control status",
        { S0010: [:status,:intersection] }
    end

    # Verify status S0011 yellow flash
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'yellow flash can be read with S0011', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "yellow flash status",
        { S0011: [:status,:intersection] }
    end

    # Verify that we can activate yellow flash
    #
    # 1. Given the site is connected
    # 2. Send the control command to switch to Yellow flash
    # 3. Wait for status Yellow flash
    # 4. Send command to switch to normal control
    # 5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"
    specify 'yellow flash can be activated with M0001', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        switch_yellow_flash
        task.sleep(2)
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
    specify 'yellow flash affects all signal groups', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        timeout =  10

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
    specify 'all red can be read with S0012', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "all-red status",
        { S0012: [:status,:intersection] }
    end

    # Verify status S0013 police key
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'police key can be read with S0013', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "police key",
        { S0013: [:status] }
    end

    # Verify that we can activate dark mode
    #
    # 1. Given the site is connected
    # 2. Send the control command to switch todarkmode
    # 3. Wait for status"Controller on" = false
    # 4. Send command to switch to normal control
    # 5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"
    specify 'dark mode can be activated with M0001', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        switch_dark_mode
        switch_normal_control
      end
    end
  end
end

