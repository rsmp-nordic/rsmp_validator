RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::CommandHelpers
  include Validator::StatusHelpers

  
  # Alarms can be hard to validate unless you have a reliable
  # method of triggering them, and there is currently no way to directly triggering
  # alarms via RSMP.
  #
  # Often some alarms can be triggered manually on the equipment,
  # but since the validator is meant for automated testing, this approach is
  # not used.
  #
  # Instead a separate interface which can be scripted, like SSH,
  # must be used. If the equipment support this, you must set up scripts to
  # activate and deactive alarms. These scripts will then be used in the tests
  # to trigger alarms.
  #
  # If you have no way of triggering the relevant alarm via a scripts, skipping
  # the test is recommended.

  describe 'Alarm' do
        
    # Validate that a detector logic fault A0301 is raises and removed.
    # This test expects that the TLC is programmed so that an alarm
    # is raise when a specific input is activated.
    # 1. Given the site is connected
    # 2. When we force input to True
    # 3. Then we should receive an active alarm
    # 4. When we force the input to False
    # 5. Then the alarm should become inactive
    specify 'Alarm A0301 is raised when input is activated', :script, sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site

        # get config
        alarm_code_id = 'A0301'                                        # what alarm to expect
        input_nr = Validator.config['alarm_activation'][alarm_code_id] # what input to activate 
        timeout  = Validator.config['timeouts']['alarm']

        force_input_and_confirm input:input_nr, value:'False'    #force input to false

        mapping = {
          'True' => 'Active',    # alarm should be raised when input is activated
          'False' => 'inActive'  # alarm should be deactivated when input is deactivated
        }

        mapping.each_pair do |input_value, alarm_status|
          log_confirmation "Waiting for alarm #{alarm_code_id} to be #{alarm_status}" do
            collect_task = task.async do
              collector = RSMP::AlarmCollector.new( site,
                num: 1,
                query: { 'aCId' =>  alarm_code_id, 'aSp' =>  'Issue', 'aS' => alarm_status },
                timeout: timeout
              )
              collector.collect!  # the bang (!) version raises an error if we time out

              alarm = collector.messages.first
              alarm_time = Time.parse(alarm.attributes["aTs"])
              expect(alarm_time).to be_within(1.minute).of Time.now.utc
            end
            force_input_and_confirm input:input_nr, value:input_value
            collect_task.wait
          end
        end
      ensure
        # always release the input
        force_input status: 'False', input: input_nr.to_s, value: 'False'
      end
    end

    # Validate that a detector logic fault raises A0302.
    #
    # 1. Given the site is connected
    # 2. When we trigger an alarm using an external script
    # 3. Then we should receive ana alarm

    specify 'A0302 is raised when a detector logic is faulty', :script, sxl: '>=1.0.7' do |example|
      skip "Don't yet have a reliable way of triggering alarms"
      skip_unless_scripts_are_configured
      Validator::Site.connected do |task,supervisor,site|
        component = Validator.config['components']['detector_logic'].keys.first
        with_alarm_activated do
          site.log "Waiting for alarm", level: :test
          start_time = Time.now
          alarm_code_id = 'A0301'
          collector = site.collect_alarms num: 1, component: component, aCId: alarm_code_id,
            aSp: 'Issue', aS: 'Active', timeout: Validator.config['timeouts']['alarm']

          alarm = collector.message
          delay = Time.now - start_time
          site.log "alarm confirmed after #{delay.to_i}s", level: :test

          alarm_time = Time.parse(alarm.attributes["aTs"])
          expect(alarm_time).to be_within(1.minute).of Time.now.utc
        end
      end
    end

    # Validate that an alarm can be acknowledged.
    #
    # 1. Given the site is connected
    # 2. When we trigger an alarm using an external script
    # 3. Then we should receive an alarm
    # 4. When we acknowledgement the alarm
    # 5. Then we should receive a confirmation

    it 'can be acknowledged', :script do |example|
      skip "Don't yet have a reliable way of triggering alarms"
      skip_unless_scripts_are_configured
      Validator::Site.connected do |task,supervisor,site|
        component = Validator.config['components']['detector_logic'].keys.first

        with_alarm_activated do
          site.log "Waiting for alarm", level: :test
          start_time = Time.now
          message, response = nil,nil
          alarm_code_id = 'A0301'

          collector = site.collect_alarms num: 1, component: component, aCId: alarm_code_id,
            aSp: 'Issue', aS: 'Active', timeout: Validator.config['timeouts']['alarm']
        end
        # TODO
      end
    end

    # Validate that alarm triggered during a RSMP disconnect is buffered
    # and send once the RSMP connection is reestablished.
    #
    # 1. Given the site is disconnected
    # 2. And we trigger an alarm using an external script
    # 3. When the site reconnects
    # 4. Then we should received an alarm

    it 'is buffered during disconnect', :script, sxl: '>=1.0.7' do |example|
      skip "Don't yet have a reliable way of triggering alarms"
      skip_unless_scripts_are_configured
      Validator::Site.stop
      with_alarm_activated do
        Validator::Site.connected do |task,supervisor,site|
          component = Validator.config['components']['detector_logic'].keys.first
          log_confirmation "Waiting for alarm" do
            collector = site.collect_alarms num: 1, component: component, aCId: 'A0302',
              aSp: 'Issue', aS: 'Active', timeout: Validator.config['timeouts']['alarm']      

            alarm = collector.message
            alarm_time = Time.parse(alarm.attributes["aTs"])
            expect(alarm_time).to be_within(1.minute).of Time.now.utc
            expect(alarm.attributes['rvs']).to eq([{
              "n"=>"detector","v"=>"1"},
              {"n"=>"type","v"=>"loop"},
              {"n"=>"errormode","v"=>"on"},
              {"n"=>"manual","v"=>"True"},
              {"n"=>"logicerror","v"=>"always_off"}
            ])
          end
        end
      end
    end
  end
end
