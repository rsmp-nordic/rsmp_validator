RSpec.describe 'RSMP site commands' do  
  include CommandHelpers
  include StatusHelpers

  def check_scripts
    raise "Aborting test because script config is missing" unless SCRIPT_PATHS
    raise "Aborting test because script config is missing" unless SCRIPT_PATHS['activate_alarm']
    raise "Aborting test because script config is missing" unless SCRIPT_PATHS['deactivate_alarm']
  end

  it 'M0104 set date', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      date = Time.new 2020,9,29,17,29,51,'UTC'
      set_date date
    end
  end

  it 'Check status S0096', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      @site.log "Set date", level: :test

      sent = Time.new 2020,9,29,17,29,51,'UTC'
      set_date sent

      status_list = { S0096: [
        :year,
        :month,
        :day,
        :hour,
        :minute,
        :second,
      ] }

      message, result = @site.request_status @component, convert_status_list(status_list), collect: {
        timeout: SUPERVISOR_CONFIG['status_update_timeout']
      }
      status = "S0096"

      received = Time.new result[{"sCI" => status, "n" => "year"}]["s"],
      result[{"sCI" => status, "n" => "month"}]["s"],
      result[{"sCI" => status, "n" => "day"}]["s"],
      result[{"sCI" => status, "n" => "hour"}]["s"],
      result[{"sCI" => status, "n" => "minute"}]["s"],
      result[{"sCI" => status, "n" => "second"}]["s"],
      'UTC'

      max_diff = SUPERVISOR_CONFIG['command_response_timeout'] + SUPERVISOR_CONFIG['status_response_timeout']
      diff = received - sent
      expect(diff.abs).to be <= max_diff
      
    ensure
      reset_date
    end
  end

  it 'Check statusResponse timestamp', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      @site.log "Set date", level: :test

      sent = Time.new 2020,9,29,17,29,51,'UTC'
      set_date sent

      status_list = { S0096: [
        :year,
        :month,
        :day,
        :hour,
        :minute,
        :second,
      ] }
      message, result = @site.request_status @component, convert_status_list(status_list), collect: {
        timeout: SUPERVISOR_CONFIG['status_update_timeout']
      }

      max_diff = SUPERVISOR_CONFIG['command_response_timeout'] + SUPERVISOR_CONFIG['status_response_timeout']
      message_diff = message.timestamp - sent
      expect(message_diff.abs).to be <= max_diff
      
    ensure
      reset_date
    end
  end

  it 'Check aggregatedStatusResponse timestamp', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      @site.log "Set date", level: :test

      sent = Time.new 2020,9,29,17,29,51,'UTC'
      set_date sent

      message = site.request_aggregated_status MAIN_COMPONENT, collect: {
        timeout: SUPERVISOR_CONFIG['status_response_timeout']
      }
      puts message.timestamp
      
      max_diff = SUPERVISOR_CONFIG['command_response_timeout'] + SUPERVISOR_CONFIG['status_response_timeout']
      message_diff = message.timestamp - sent
      expect(message_diff.abs).to be <= max_diff
      
    ensure
      reset_date
    end
  end

  it 'Check commandResponse timestamp', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      @site.log "Set date", level: :test

      sent = Time.new 2020,9,29,17,29,51,'UTC'
      set_date sent

      message, result = set_security_code 2
      puts message[:timestamp]

      max_diff = SUPERVISOR_CONFIG['command_response_timeout'] + SUPERVISOR_CONFIG['status_response_timeout']
      message_diff = message[:timestamp] - sent
      expect(message_diff.abs).to be <= max_diff
      
    ensure
      reset_date
    end
  end

  it 'Check commandResponse timestamp M0104 edge case', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      @site.log "Set date", level: :test

      sent = Time.new 2020,9,29,17,29,51,'UTC'
      message, result = set_date sent
      puts message[:timestamp]

      max_diff = SUPERVISOR_CONFIG['command_response_timeout'] + SUPERVISOR_CONFIG['status_response_timeout']
      message_diff = message[:timestamp] - sent
      expect(message_diff.abs).to be <= max_diff
      
    ensure
      reset_date
    end
  end

  it 'Check alarm timestamp', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      check_scripts
      prepare task, site
      @site.log "Test timestamp of alarm", level: :test

      sent = Time.new 2020,9,29,17,29,51,'UTC'
      set_date sent      

      component = COMPONENT_CONFIG['detector_logic'].keys.first
      system(SCRIPT_PATHS['activate_alarm'])
      site.log "Waiting for alarm", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        response = site.wait_for_alarm task, component: component, aCId: 'A0302',
          aSp: 'Issue', aS: 'Active', timeout: RSMP_CONFIG['alarm_timeout']
      end.to_not raise_error, "Did not receive alarm"

      max_diff = SUPERVISOR_CONFIG['command_response_timeout'] + SUPERVISOR_CONFIG['status_response_timeout']
      message_diff = Time.parse(response[:message].attributes["aTs"])- sent
      expect(message_diff.abs).to be <= max_diff
      
    ensure
      reset_date
    end
  end
end