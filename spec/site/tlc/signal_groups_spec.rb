RSpec.describe 'Traffic Light Controller' do  
  include CommandHelpers
  include StatusHelpers

  describe "Signal Group" do
    # Validate that a signal group can be ordered to green using the M0002 command.
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

    describe 'state' do
      # Verify that the controller responds to S0001.
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      it 'is read with S0001', sxl: '>=1.0.7' do |example|
        request_status_and_confirm "signal group status",
          { S0001: [:signalgroupstatus, :cyclecounter, :basecyclecounter, :stage] }
      end
    end

    describe 'red/green predictions' do
      # Verify status S0025 time-of-green/time-of-red
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      it 'is read with S0025', sxl: '>=1.0.13' do |example|
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
    end

    describe 'series' do
      # 1. Verify connection
      # 2. Send control command to start or stop a serie of signalgroups
      # 3. Wait for status = true  
      it 'can be started/stopped with M0012', :important, sxl: '>=1.0.8' do |example|
        Validator::Site.connected do |task,supervisor,site|
          prepare task, site
          set_signal_start_or_stop '5,4134,65;5,11'
        end
      end
    end
 
     describe 'list' do
      # Verify status S0017 number of signal groups
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      specify 'size is read with S0017', sxl: '>=1.0.7' do |example|
        request_status_and_confirm "number of signal groups",
          { S0017: [:number] }
      end
    end
  end
end