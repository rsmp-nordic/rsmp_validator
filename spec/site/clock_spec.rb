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
      date = Time.new 2020,9,29,17,29,51,'UTC'
      with_date_set date do
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
        diff = received - date
        expect(diff.abs).to be <= max_diff
      end
    end
  end

  it 'Check status response timestamp', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      date = Time.new 2020,9,29,17,29,51,'UTC'
      with_date_set date do
        status_list = { S0096: [
          :year,
          :month,
          :day,
          :hour,
          :minute,
          :second,
        ] }

        # start collect
        collect_task = @task.async do |task|
          site.collect task, type: "StatusResponse", num: 1, timeout: SUPERVISOR_CONFIG['status_response_timeout']
        end
        
        site.request_status @component, convert_status_list(status_list) # request status
        response = collect_task.wait # and wait for the first status response

        max_diff = SUPERVISOR_CONFIG['command_response_timeout'] + SUPERVISOR_CONFIG['status_response_timeout']
        diff = Time.parse(response.attributes['sTs']) - date
        expect(diff.abs).to be <= max_diff
      end
    end
  end

  it 'Check aggregated status response timestamp', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      date = Time.new 2020,9,29,17,29,51,'UTC'
      with_date_set date do
        request, response = site.request_aggregated_status MAIN_COMPONENT, collect: {
          timeout: SUPERVISOR_CONFIG['status_response_timeout']
        }
        max_diff = SUPERVISOR_CONFIG['command_response_timeout'] + SUPERVISOR_CONFIG['status_response_timeout']
        diff = Time.parse(response.attributes['aSTS']) - date
        expect(diff.abs).to be <= max_diff
      end
    end
  end

  it 'Check command response timestamp', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      date = Time.new 2020,9,29,17,29,51,'UTC'
      with_date_set date do
        # TODO
        # need to send a command requeest and collect a response to check the timestamp
      end
    end
  end

  it 'Check timestamp of M0104 command response', sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      date = Time.new 2020,9,29,17,29,51,'UTC'
      with_date_set date do
        # TODO
        # need to collect the command response from the m0104 request and check the timestamp
      end     
    end
  end

  it 'Check alarm timestamp', :script, sxl: '>=1.0.7' do |example|
    TestSite.connected do |task,supervisor,site|
      check_scripts
      prepare task, site
      date = Time.new 2020,9,29,17,29,51,'UTC'
      with_date_set date do
        component = COMPONENT_CONFIG['detector_logic'].keys.first
        system(SCRIPT_PATHS['activate_alarm'])
        site.log "Waiting for alarm", level: :test
        response = site.wait_for_alarm task, timeout: RSMP_CONFIG['alarm_timeout']

        max_diff = SUPERVISOR_CONFIG['command_response_timeout'] + SUPERVISOR_CONFIG['status_response_timeout']
        diff = Time.parse(response.attributes['sTs']) - date
        expect(diff.abs).to be <= max_diff
      end
    end
  end
end