RSpec.describe 'RSMP M0104 clock and timestamps' do
  include CommandHelpers
  include StatusHelpers

  DATE = Time.new 2020,9,29,17,29,51,'UTC'

  def check_scripts
    raise "Aborting test because script config is missing" unless SCRIPT_PATHS
    raise "Aborting test because script config is missing" unless SCRIPT_PATHS['activate_alarm']
    raise "Aborting test because script config is missing" unless SCRIPT_PATHS['deactivate_alarm']
  end

# 1. Given the site is connected
# 2. Send control command to set_date
# 3. Wait for status = true
# 4. Send control command to set_date
# 5. Wait for status = true  
  it 'accepts M0104 set date', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      set_date(DATE)
    end
  end

# 1. Given the site is connected
# 2. Send control command to set_date
# 3. Wait for status = true
# 4. Send comand to get Current date 
# 5. compare set_date and Current date Max_diff from site config  
  it 'status S0096 after changing date', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
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
        request, response = @site.request_status @component, convert_status_list(status_list), collect: {
          timeout: SUPERVISOR_CONFIG['status_update_timeout']
        }
        status = "S0096"

        received = Time.new response[{"sCI" => status, "n" => "year"}]["s"],
        response[{"sCI" => status, "n" => "month"}]["s"],
        response[{"sCI" => status, "n" => "day"}]["s"],
        response[{"sCI" => status, "n" => "hour"}]["s"],
        response[{"sCI" => status, "n" => "minute"}]["s"],
        response[{"sCI" => status, "n" => "second"}]["s"],
        'UTC'

        max_diff = SUPERVISOR_CONFIG['command_response_timeout'] + 
                   SUPERVISOR_CONFIG['status_response_timeout']
        diff = received - DATE
        expect(diff.abs).to be <= max_diff
      end
    end
  end

# 1. Given the site is connected
# 2. Send control command to set_date
# 3. Wait for status = true
# 4. Send command to get one ore more status
# 5. compare set_date and Status_date Max_diff from site config  
  it 'status response timestamp after changing date', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
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
        
        request, response, messages = site.request_status @component,
          convert_status_list(status_list),
          collect: {
            timeout: SUPERVISOR_CONFIG['status_response_timeout']
          }

        message = messages.first
        max_diff = SUPERVISOR_CONFIG['command_response_timeout'] + SUPERVISOR_CONFIG['status_response_timeout']
        diff = Time.parse(message.attributes['sTs']) - DATE
        expect(diff.abs).to be <= max_diff
      end
    end
  end

# 1. Given the site is connected
# 2. Send control command to set_date
# 3. Wait for status = true
# 4. Send comand to get agregated status
# 5. compare set_date and Status_date  on all agregated status Max_diff from site config
  it 'aggregated status response timestamp after changing date', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      with_date_set DATE do
        request, response = site.request_aggregated_status MAIN_COMPONENT, collect: {
          timeout: SUPERVISOR_CONFIG['status_response_timeout']
        }
        max_diff = SUPERVISOR_CONFIG['command_response_timeout'] + SUPERVISOR_CONFIG['status_response_timeout']
        diff = Time.parse(response.attributes['aSTS']) - DATE
        expect(diff.abs).to be <= max_diff
      end
    end
  end

# 1. Given the site is connected
# 2. Send control command to setset_date
# 3. Wait for status = true
# 4. Send command
# 5. compare set_date and comand response timestamp Max_diff from site config
  it 'command response timestamp after changing date', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      with_date_set DATE do
        request, response, messages = set_functional_position 'NormalControl'
        message = messages.first
        max_diff = SUPERVISOR_CONFIG['command_response_timeout'] * 2
        diff = Time.parse(message.attributes['cTS']) - DATE
        expect(diff.abs).to be <= max_diff
      end
    end
  end

# 1. Given the site is connected
# 2. Send control command to setset_date
# 3. compare set_date and response time stamp Max_diff from site config
# 4. Send control command to setset_date
# 5. Wait for status = true
  it 'timestamp of M0104 command response', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      with_date_set DATE do
        request, response, messages = set_functional_position 'NormalControl'
        message = messages.first
        max_diff = SUPERVISOR_CONFIG['command_response_timeout']
        diff = Time.parse(message.attributes['cTS']) - DATE
        expect(diff.abs).to be <= max_diff
      end
    end
  end

# 1. Given the site is connected
# 2. Send control command to set_date
# 3. Wait for status = true
# 4. Trigger alarm from Script
# 5. Wait for alarm
# 6. compare set_date and alarm response timestamp Max_diff from site config
  it 'alarm timestamp after changing date', :script, sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      check_scripts
      prepare task, site
      with_date_set DATE do
        component = COMPONENT_CONFIG['detector_logic'].keys.first
        system(SCRIPT_PATHS['activate_alarm'])
        site.log "Waiting for alarm", level: :test
        response = site.wait_for_alarm task, timeout: RSMP_CONFIG['alarm_timeout']
        max_diff = SUPERVISOR_CONFIG['command_response_timeout'] + SUPERVISOR_CONFIG['status_response_timeout']
        diff = Time.parse(response.attributes['sTs']) - DATE
        expect(diff.abs).to be <= max_diff
      end
    end
  end

# 1. Given the site is connected
# 2. Send control command to setset_date
# 3. Wait for Watchdog
# 4. compare set_date and alarm response timestamp Max_diff from site config
  it 'watchdog timestamp after changing date', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      with_date_set DATE do
        response = site.collect task, type: "Watchdog", num: 1, timeout: SUPERVISOR_CONFIG['watchdog_timeout']
        max_diff = SUPERVISOR_CONFIG['command_response_timeout'] + SUPERVISOR_CONFIG['status_response_timeout']
        diff = Time.parse(response.attributes['wTs']) - DATE
        expect(diff.abs).to be <= max_diff
      end
    end
  end
end