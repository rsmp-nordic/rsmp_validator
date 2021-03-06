RSpec.describe 'Traffic Light Controller' do  
  include CommandHelpers
  include StatusHelpers

  describe "System" do

    # Verify status S0091 operator logged in/out OP-panel
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0091 operator logged in/out OP-panel', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "operator logged in/out OP-panel",
        { S0091: [:status, :user] }
    end

    # Verify status S0092 operator logged in/out web-interface
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0092 operator logged in/out web-interface', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "operator logged in/out web-interface",
        { S0092: [:status, :user] }
    end

    # Verify status S0095 version of traffic controller
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0095 version of traffic controller', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "version of traffic controller",
        { S0095: [:status] }
    end

    # 1. Verify connection i Isolated_mode
    # 2. Send the control command to restart, include security_code
    # 3. Wait for status response= stopped
    # 4. Reconnect as Isolated_mode
    # 5. Wait for status= ready
    # 6. Send command to switch to normal controll
    # 7. Wait for status "Yellow flash" = false, "Controller starting"= false, "Controller on"= true
    it 'M0004 restart', sxl: '>=1.0.7' do |example|
      Validator::Site.isolated do |task,supervisor,site|
        prepare task, site
        #if ask_user site, "Going to restart controller. Press enter when ready or 's' to skip:"
        set_restart
        site.wait_for_state :stopped, Validator.config['timeouts']['shutdown']
      end

      # NOTE
      # when a remote site closes the connection, our site proxy object will stop.
      # when the site reconnects, a new site proxy object will be created.
      # this means we can't wait for the old site to become ready
      # it also means we need a new Validator::Site.
      Validator::Site.isolated do |task,supervisor,site|
        prepare task, site
        site.wait_for_state :ready, Validator.config['timeouts']['ready']
        wait_normal_control
      end
    end

    # 1. Verify connection
    # 2. Send control command to set securitycode_level
    # 3. Wait for status = true
    # 4. Send control command to setsecuritycode_level
    # 5. Wait for status = true
    it 'M0103 set security code', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        set_security_code 1
        set_security_code 2
      end
    end

    it 'Send the wrong security code', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        wrong_security_code 
      end
    end

  end
end
