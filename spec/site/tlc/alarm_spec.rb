RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::CommandHelpers
  include Validator::StatusHelpers

  # Testing alarms require a reliable way of rainsing them.
  #
  # There's no way to trigger alarms directly via RSMP yet,
  # but often you can program the equipment to raise an alarm
  # when a specific input is activated. If that's the case,
  # set the `alarm_activcation` item in the validator config to
  # specify which input activates which alarm. See docs for details.
  #
  # Triggered alarms manually on the equipment is not used,
  # because validator is meant for automated testing.

  describe 'Alarm' do
        
    # Validate that a detector logic fault A0301 is raises and cleared.
    #
    # The test requires that the device is programmed so that the alarm
    # is raise when a specific input is activated, as specified in the
    # test configuration.
    #
    # 1. Given the site is connected
    # 2. When we force the input to True
    # 3. Then an alarm should be raised, with a timestamp close to now
    # 4. When we force the input to False
    # 5. Then the alarm issue should become inactive, with a timestamp close to now

    specify 'Alarm A0301 is raised when input is activated', :programming, sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        alarm_code_id = 'A0301'
        prepare task, site
        def verify_timestamp alarm, duration=1.minute
          alarm_time = Time.parse(alarm.attributes["aTs"])
          expect(alarm_time).to be_within(duration).of Time.now.utc
        end
        deactivate = with_alarm_activated(task, site, alarm_code_id) do |alarm|   # raise alarm, by activating input
          verify_timestamp alarm
          log "Alarm #{alarm_code_id} is now Active"
        end
        verify_timestamp deactivate
        log "Alarm #{alarm_code_id} is now Inactive"
      end
    end

    # Validate that a detector logic fault A0302 is raises and cleared.
    #
    # The test requires that the device is programmed so that the alarm
    # is raise when a specific input is activated, as specified in the
    # test configuration.
    #
    # 1. Given the site is connected
    # 2. When we force the input to True
    # 3. Then an alarm should be raised, with a timestamp close to now
    # 4. When we force the input to False
    # 5. Then the alarm issue should become inactive, with a timestamp close to now

    specify 'A0302 is raised when a detector logic is faulty', :programming, sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        alarm_code_id = 'A0302'
        prepare task, site
        def verify_timestamp alarm, duration=1.minute
          alarm_time = Time.parse(alarm.attributes["aTs"])
          expect(alarm_time).to be_within(duration).of Time.now.utc
        end
        deactivate = with_alarm_activated(task, site, alarm_code_id) do |alarm|   # raise alarm, by activating input
          verify_timestamp alarm
          log "Alarm #{alarm_code_id} is now Active"
        end
        verify_timestamp deactivate
        log "Alarm #{alarm_code_id} is now Inactive"
      end
    end

    # Validate that an alarm can be acknowledged.
    #
    # The test expects that the TLC is programmed so that an detector logic fault
    # alarm A0301 is raised and can be acknowledged when a specific input is activated.
    # The alarm code and input nr is read from the test configuration.
    #
    # 1. Given the site is connected
    # 2. When we trigger an alarm
    # 2. Then we should receive an unacknowledged alarm issue 
    # 4. When we acknowledge the alarm
    # 5. Then we should recieve an acknowledged alarm issue

    specify 'A0301 can be acknowledged when input is activated', :programming, sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        alarm_code_id = 'A0301'   # what alarm to expect
        timeout  = Validator.config['timeouts']['alarm']

        log "Activating alarm #{alarm_code_id}"
        deactivate = with_alarm_activated(task, site, alarm_code_id) do |alarm|   # raise alarm, by activating input
          log "Alarm #{alarm_code_id} is now active"

          # verify timestamp
          alarm_time = Time.parse(alarm.attributes["aTs"])
          expect(alarm_time).to be_within(1.minute).of Time.now.utc

          # test acknowledge and confirm
          log "Acknowledge alarm #{alarm_code_id}"

          collect_task = task.async do
            RSMP::AlarmCollector.new(site,
              num: 1,
              query: {'aCId'=>alarm_code_id, 'aSp' => /Issue/i, 'ack' => /Acknowledged/i, 'aS' => 'Active'},
              timeout: timeout
            ).collect!
          end

          m_id = RSMP::Message.make_m_id  # generate a message id, that can be used to listen for repsonses
          alarm = RSMP::AlarmAcknowledged.new(
            'mId' => m_id,
            'cId' => Validator.config['main_component'],
            'aTs' => site.clock.to_s,
            'aCId' => alarm_code_id
          )

          ## note: the json schema needs to be updated,
          ## it currently requires the attributes "ack", "aS", "sS", "cat", "pri", "rvs",
          ## even when it's an alarm suspend message.
          ## as a temporary work-around, outgoing json schema validation can be disabled when sending
          site.send_message alarm, nil, validate: false
          messages = collect_task.wait
          expect(messages).to be_an(Array)
          expect(messages.first).to be_a(RSMP::Alarm)
        end
      end
    end

    # Validate that alarms can be suspended. We're using A0301 in this test.
    #
    # 1. Given the site is connected
    # 2. And the alarm is  resumed
    # 3. When we suspend the alarm
    # 4. Then we should received an alarm suspended messsage
    # 5. When we resume the alarm
    # 6. Then we should receive an alarm resumed message

    it 'can be suspended and resumed' do
      Validator::Site.connected do |task,supervisor,site|
        alarm_code = 'A0301'

        # first resume to make sure something happens when we suspend
        resume = RSMP::AlarmResume.new(
          'cId' => Validator.config['main_component'],
          'aCId' => alarm_code
        )
        site.send_message resume

        # now suspend the alarm while collecting responses
        suspend = RSMP::AlarmSuspend.new(
          'mId' => RSMP::Message.make_m_id,     # generate a message id, that can be used to listen for responses
          'cId' => Validator.config['main_component'],
          'aCId' => alarm_code
        )
        collect_task = task.async do
          RSMP::AlarmCollector.new(site,
            m_id: suspend.m_id,
            num: 1,
            query: {'aCI'=>alarm_code,'aSp'=>'Suspend','sS'=>'suspended'},
            timeout: Validator.config['timeouts']['alarm']
          ).collect!
        end
        begin
          site.send_message suspend
          messages = collect_task.wait
          expect(messages).to be_an(Array)
          message = messages.first
          expect(message).to be_a(RSMP::AlarmSuspended)
        rescue
          site.send_message resume    # clean up by resuming alarm
          raise
        end

          # clean up by resuming alarm
        resume.attributes['mId'] = RSMP::Message.make_m_id  # generate a message id, that can be used to listen for responses
        collect_task = task.async do
          RSMP::AlarmCollector.new(site, 
            m_id: resume.m_id,
            num: 1,
            query: {'aCI'=>alarm_code,'aSp'=>'Suspend','sS'=>'notSuspended'},
            timeout: Validator.config['timeouts']['alarm']
          ).collect!
        end
        site.send_message resume
        messages = collect_task.wait
        expect(messages).to be_an(Array)
        message = messages.first
        expect(message).to be_a(RSMP::AlarmResumed)
      end
    end
  end
end
