RSpec.describe "Traffic Light Controller" do
  include StatusHelpers
  include CommandHelpers

  describe "Operational Modes" do
    
    # Verify status S0020 control mode
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0020 control mode', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "control mode",
        { S0020: [:controlmode,:intersection] }
    end

    # Verify status S0005 traffic controller starting
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0005 traffic controller starting', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "traffic controller starting (true/false)",
        { S0005: [:status] }
    end


    # Verify status S0006 emergency stage
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0006 emergency stage', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "emergency stage status",
        { S0006: [:status,:emergencystage] }
    end

    # Verify status S0007 controller switched on (dark mode=off)
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0007 controller switched on (dark mode=off)', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "controller switch on (dark mode=off)",
        { S0007: [:status,:intersection] }
    end

    # Verify status S0008 manual control
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0008 manual control', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "manual control status",
        { S0008: [:status,:intersection] }
    end

    # Verify status S0009 fixed time control
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0009 fixed time control', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "fixed time control status",
        { S0009: [:status,:intersection] }
    end

    # Verify status S0010 isolated control
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0010 isolated control', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "isolated control status",
        { S0010: [:status,:intersection] }
    end

    # Verify status S0011 yellow flash
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0011 yellow flash', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "yellow flash status",
        { S0011: [:status,:intersection] }
    end

    # Verify status S0012 all red
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0012 all red', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "all-red status",
        { S0012: [:status,:intersection] }
    end

    # Verify status S0013 police key
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0013 police key', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "police key",
        { S0013: [:status] }
    end

    # Verify that we can activate yellow flash
    #
    # 1. Given the site is connected
    # 2. Send the control command to switch to Yellow flash
    # 3. Wait for status Yellow flash
    # 4. Send command to switch to normal control
    # 5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"
    it 'M0001 set yellow flash', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        switch_yellow_flash
        switch_normal_control
      end
    end

    # Verify that we can activate dark mode
    #
    # 1. Given the site is connected
    # 2. Send the control command to switch todarkmode
    # 3. Wait for status"Controller on" = false
    # 4. Send command to switch to normal control
    # 5. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true"
    it 'M0001 set dark mode', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        switch_dark_mode
        switch_normal_control
      end
    end

    # 1. Verify connection
    # 2. Send the control command to switch to  fixed time= true
    # 3. Wait for status = true
    # 4. Send control command to switch "fixed time"= true
    # 5. Wait for status = false
    it 'M0007 set fixed time', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        switch_fixed_time 'True'
        switch_fixed_time 'False'
      end
    end



  end
end

