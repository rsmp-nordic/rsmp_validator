RSpec.describe "Traffic Light Controller" do
  include CommandHelpers
  include StatusHelpers
  
  describe 'Clock' do
    DATE = Time.new 2020,9,29,17,29,51,'UTC'
 
    # Verify status 0096 current date and time
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'S0096 current date and time', sxl: '>=1.0.7'  do |example|
      request_status_and_confirm "current date and time",
        { S0096: [
          :year,
          :month,
          :day,
          :hour,
          :minute,
          :second,
        ] }
    end

    # Verify that the controller responds to M0104
    #
    # 1. Given the site is connected
    # 2. Send command
    # 3. Expect status response before timeout
    it 'sets clock with M0104', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        set_date(DATE)
      end
    end

    # Verify status S0096 date after changing date
    #
    # 1. Given the site is connected
    # 2. Send control command to set_date
    # 3. Request status S0096
    # 4. Compare set_date and status timestamp
    # 5. Expect the difference to be within max_diff
    it 'reports adjusted clock in S0096', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        with_date_set DATE do
          status_list = { S0096: [
            :year,
            :month,
            :day,
            :hour,
            :minute,
            :second,
          ] }
          request, response = site.request_status Validator.config['main_component'], convert_status_list(status_list), collect: {
            timeout: Validator.config['timeouts']['status_update']
          }
          status = "S0096"

          received = Time.new response[{"sCI" => status, "n" => "year"}]["s"],
          response[{"sCI" => status, "n" => "month"}]["s"],
          response[{"sCI" => status, "n" => "day"}]["s"],
          response[{"sCI" => status, "n" => "hour"}]["s"],
          response[{"sCI" => status, "n" => "minute"}]["s"],
          response[{"sCI" => status, "n" => "second"}]["s"],
          'UTC'

          max_diff = Validator.config['timeouts']['command_response'] + 
                    Validator.config['timeouts']['status_response']
          diff = received - DATE
          expect(diff.abs).to be <= max_diff
        end
      end
    end

    # Verify status response timestamp after changing date
    #
    # 1. Given the site is connected
    # 2. Send control command to set_date
    # 3. Request status S0096
    # 4. Compare set_date and response timestamp
    # 5. Expect the difference to be within max_diff
    it 'timestamps S0096 with adjusted clock', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        with_date_set DATE do
          status_list = { S0096: [
            :year,
            :month,
            :day,
            :hour,
            :minute,
            :second,
          ] }
          
          request, response, messages = site.request_status Validator.config['main_component'],
            convert_status_list(status_list),
            collect: {
              timeout: Validator.config['timeouts']['status_response']
            }

          message = messages.first
          max_diff = Validator.config['timeouts']['command_response'] + Validator.config['timeouts']['status_response']
          diff = Time.parse(message.attributes['sTs']) - DATE
          expect(diff.abs).to be <= max_diff
        end
      end
    end

    # Verify aggregated status response timestamp after changing date
    #
    # 1. Given the site is connected
    # 2. Send control command to set date
    # 3. Wait for status = true
    # 4. Request aggregated status
    # 5. Compare set_date and response timestamp
    # 6. Expect the difference to be within max_diff
    it 'timestamps aggregated status response with adjusted clock', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        with_date_set DATE do
          request, response = site.request_aggregated_status Validator.config['main_component'], collect: {
            timeout: Validator.config['timeouts']['status_response']
          }
          max_diff = Validator.config['timeouts']['command_response'] + Validator.config['timeouts']['status_response']
          diff = Time.parse(response.attributes['aSTS']) - DATE
          expect(diff.abs).to be <= max_diff
        end
      end
    end

    # Verify command response timestamp after changing date
    #
    # 1. Given the site is connected
    # 2. Send control command to set date
    # 3. Send command to set functional position
    # 4. Compare set_date and response timestamp
    # 5. Expect the difference to be within max_diff
    it 'timestamps command response with adjusted clock', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        with_date_set DATE do
          request, response, messages = set_functional_position 'NormalControl'
          message = messages.first
          max_diff = Validator.config['timeouts']['command_response'] * 2
          diff = Time.parse(message.attributes['cTS']) - DATE
          expect(diff.abs).to be <= max_diff
        end
      end
    end

    # Verify command response timestamp after changing date
    #
    # 1. Given the site is connected
    # 2. Send control command to set date
    # 3. Send command to set functional position
    # 4. Compare set_date and response timestamp
    # 5. Expect the difference to be within max_diff
    it 'timestamps M0104 command response with adjusted clock', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        with_date_set DATE do
          request, response, messages = set_functional_position 'NormalControl'
          message = messages.first
          max_diff = Validator.config['timeouts']['command_response']
          diff = Time.parse(message.attributes['cTS']) - DATE
          expect(diff.abs).to be <= max_diff
        end
      end
    end

    # Verify timestamp of alarm after changing date
    #
    # 1. Given the site is connected
    # 2. Send control command to set_date
    # 3. Wait for status = true
    # 4. Trigger alarm from Script
    # 5. Wait for alarm
    # 6. Compare set_date and alarm response timestamp
    # 7. Expect the difference to be within max_diff
    it 'timestamps alarm with adjusted clock', :script, sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        Validator.require_scripts
        prepare task, site
        with_date_set DATE do
          component = Validator.config['components']['detector_logic'].keys.first
          system(Validator.config['scripts']['activate_alarm'])
          site.log "Waiting for alarm", level: :test
          response = site.wait_for_alarm task, timeout: Validator.config['timeouts']['alarm']
          max_diff = Validator.config['timeouts']['command_response'] + Validator.config['timeouts']['status_response']
          diff = Time.parse(response.attributes['sTs']) - DATE
          expect(diff.abs).to be <= max_diff
        end
      end
    end

    # Verify timestamp of watchdog after changing date
    #
    # 1. Given the site is connected
    # 2. Send control command to setset_date
    # 3. Wait for Watchdog
    # 4. Compare set_date and alarm response timestamp
    # 5. Expect the difference to be within max_diff
    it 'timestamps watchdog messages with adjusted clock', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        with_date_set DATE do
          response = site.collect task, type: "Watchdog", num: 1, timeout: Validator.config['timeouts']['watchdog']
          max_diff = Validator.config['timeouts']['command_response'] + Validator.config['timeouts']['status_response']
          diff = Time.parse(response.attributes['wTs']) - DATE
          expect(diff.abs).to be <= max_diff
        end
      end
    end
  end
end