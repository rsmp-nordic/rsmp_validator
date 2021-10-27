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
    before { skip "Don't yet have a reliable way of triggering alarms" }

    # Validate that a detector logic fault raises A0302.
    #
    # 1. Given the site is connected
    # 2. When we trigger an alarm using an external script
    # 3. Then we should receive ana alarm

    specify 'A0302 is raised when a detector logic is faulty', :script, sxl: '>=1.0.7' do |example|
      skip_unless_scripts_are_configured
      Validator::Site.connected do |task,supervisor,site|
        component = Validator.config['components']['detector_logic'].keys.first
        with_alarm_activated do
          site.log "Waiting for alarm", level: :test
          start_time = Time.now
          alarm_code_id = 'A0301'
          collector = site.collect_alarms task, num: 1, component: component, aCId: alarm_code_id,
            aSp: 'Issue', aS: 'Active', timeout: Validator.config['timeouts']['alarm']

          alarm = collector.message
          delay = Time.now - start_time
          site.log "alarm confirmed after #{delay.to_i}s", level: :test

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

    # Validata that an alarm can be acknowledged.
    #
    # 1. Given the site is connected
    # 2. When we trigger an alarm using an external script
    # 3. Then we should receive an alarm
    # 4. When we acknowledgement the alarm
    # 5. Then we should receive a confirmation

    it 'can be acknowledged', :script do |example|
      skip_unless_scripts_are_configured
      Validator::Site.connected do |task,supervisor,site|
        component = Validator.config['components']['detector_logic'].keys.first

        with_alarm_activated do
          site.log "Waiting for alarm", level: :test
          start_time = Time.now
          message, response = nil,nil
          alarm_code_id = 'A0301'

          collector = site.collect_alarms task, num: 1, component: component, aCId: alarm_code_id,
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
      skip_unless_scripts_are_configured
      Validator::Site.stop
      with_alarm_activated do
        Validator::Site.connected do |task,supervisor,site|
          component = Validator.config['components']['detector_logic'].keys.first
          log_confirmation "Waiting for alarm" do
            collector = site.collect_alarms task, num: 1, component: component, aCId: 'A0302',
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
