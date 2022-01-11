RSpec.describe 'Site::Traffic Light Controller' do  
  include Validator::CommandHelpers
  include Validator::StatusHelpers

  describe "Signal Group" do
    # Validate that a signal group can be ordered to green using the M0010 command.
    #
    # 1. Verify connection
    # 2. Send control command to start signalgrup, set_signal_start= true, include security_code
    # 3. Wait for status = true  
    it 'is ordered to green with M0010', :important, sxl: '>=1.0.8' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        set_signal_start
      end
    end

    # 1. Verify connection
    # 2. Send control command to stop signalgrup, set_signal_start= false, include security_code
    # 3. Wait for status = true  
    it 'is ordered to red with M0011', :important, sxl: '>=1.0.8' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        set_signal_stop
      end
    end

    # Verify that signal group status can be read with S0001.
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'state is read with S0001', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "signal group status",
        { S0001: [:signalgroupstatus, :cyclecounter, :basecyclecounter, :stage] }
    end

    # Verify that time-of-green/time-of-red can be read with S0025.
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'red/green predictions is read with S0025', sxl: '>=1.0.13' do |example|
      request_status_and_confirm "time-of-green/time-of-red",
        { S0025: [
            :minToGEstimate,
            :maxToGEstimate,
            :likelyToGEstimate,
            :ToGConfidence,
            :minToREstimate,
            :maxToREstimate,
            :likelyToREstimate
        ] },
        Validator.config['components']['signal_group'].keys.first
    end

    # 1. Verify connection
    # 2. Send control command to start or stop a serie of signalgroups
    # 3. Wait for status = true  
    specify 'series can be started/stopped with M0012', :important, sxl: '>=1.0.8' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        set_signal_start_or_stop '5,4134,65;5,11'
      end
    end

    # Verify status S0017 number of signal groups
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'list size is read with S0017', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "number of signal groups",
        { S0017: [:number] }
    end

    # Verify that groups follow startup sequence after a restart
    #
    # 1. Given the site is connected
    # 2. And has just been restarted
    # 3. Then all signal groups should follow the startup sequence
    it 'follows startup sequence after restart', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        supervisor.ignore_errors RSMP::DisconnectError do
          verify_startup_sequence do
            set_restart
            site.wait_for_state :stopped, Validator.config['timeouts']['shutdown']
            site.wait_for_state :ready, Validator.config['timeouts']['ready']
          end
        end
      end
    end

    # Verify that we can activate normal control after yellow flash mode is turned off
    #
    # 1. Given the site is connected and in yellow flash mode
    # 2. When we activate normal control
    # 3. All signal groups should go through e, f and g
    it 'follow startup sequence after yellow flash', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        verify_startup_sequence do
          switch_yellow_flash
          switch_normal_control
        end
        set_functional_position 'NormalControl'
      end
    end
  end
end