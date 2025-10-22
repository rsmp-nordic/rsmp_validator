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
      Validator::SiteTester.connected do |task,supervisor,site|
        prepare task, site
        set_signal_start
      end
    end

    # 1. Verify connection
    # 2. Send control command to stop signalgrup, set_signal_start= false, include security_code
    # 3. Wait for status = true
    it 'is ordered to red with M0011', :important, sxl: '>=1.0.8' do |example|
      Validator::SiteTester.connected do |task,supervisor,site|
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
      Validator::SiteTester.connected do |task,supervisor,site|
        request_status_and_confirm site, "signal group status",
          { S0001: [:signalgroupstatus, :cyclecounter, :basecyclecounter, :stage] }
      end
    end

    # Verify that time-of-green/time-of-red can be read with S0025.
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'red/green predictions is read with S0025', sxl: '>=1.0.13' do |example|
      Validator::SiteTester.connected do |task,supervisor,site|
        request_status_and_confirm site, "time-of-green/time-of-red",
          { S0025: [
              :minToGEstimate,
              :maxToGEstimate,
              :likelyToGEstimate,
              :ToGConfidence,
              :minToREstimate,
              :maxToREstimate,
              :likelyToREstimate
          ] },
          Validator.get_config('components','signal_group').keys.first
      end
    end

    # Verify status S0017 number of signal groups
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'list size is read with S0017', sxl: '>=1.0.7' do |example|
      Validator::SiteTester.connected do |task,supervisor,site|
        request_status_and_confirm site, "number of signal groups",
          { S0017: [:number] }
      end
    end

    # Verify that we can activate normal control after yellow flash mode is turned off
    #
    # 1. Given the site is connected and in yellow flash mode
    # 2. When we activate normal control
    # 3. All signal groups should go through e, f and g
    it 'follow startup sequence after yellow flash', sxl: '>=1.0.7', functional: true do |example|
      Validator::SiteTester.connected do |task,supervisor,site|
        prepare task, site
        verify_startup_sequence do
          switch_yellow_flash
          set_functional_position 'NormalControl'
        end
        set_functional_position 'NormalControl'
      end
    end
  end
end
