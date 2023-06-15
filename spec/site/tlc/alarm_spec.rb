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

    specify 'Alarm A0302 is raised when input is activated', :programming, sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        alarm_code_id = 'A0302'
        prepare task, site
        def verify_timestamp alarm, duration=1.minute
          alarm_time = Time.parse(alarm.attributes["aTs"])
          expect(alarm_time).to be_within(duration).of Time.now.utc
        end
        deactivated, component_id = with_alarm_activated(task, site, alarm_code_id) do |alarm,component_id|   # raise alarm, by activating input
          verify_timestamp alarm
          log "Alarm #{alarm_code_id} is now Active on component #{component_id}"
        end
        verify_timestamp deactivated
        log "Alarm #{alarm_code_id} is now Inactive on component #{component_id}"
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

    specify 'A0302 can be raised', :programming, sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        alarm_code_id = 'A0302'
        prepare task, site
        def verify_timestamp alarm, duration=1.minute
          alarm_time = Time.parse(alarm.attributes["aTs"])
          expect(alarm_time).to be_within(duration).of Time.now.utc
        end
        deactivate, component_id = with_alarm_activated(task, site, alarm_code_id) do |alarm,component_id|   # raise alarm, by activating input
          verify_timestamp alarm
          log "Alarm #{alarm_code_id} is now Active on component #{component_id}"
        end
        verify_timestamp deactivate
        log "Alarm #{alarm_code_id} is now Inactive on component #{component_id}"
      end
    end

    # Validate that an alarm can be acknowledged.
    #
    # The test expects that the TLC is programmed so that an detector logic fault
    # alarm A0302 is raised and can be acknowledged when a specific input is activated.
    # The alarm code and input nr is read from the test configuration.
    #
    # 1. Given the site is connected
    # 2. When we trigger an alarm
    # 2. Then we should receive an unacknowledged alarm issue 
    # 4. When we acknowledge the alarm
    # 5. Then we should recieve an acknowledged alarm issue

    specify 'A0302 can be acknowledged', :programming, sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site
        alarm_code_id = 'A0302'   # what alarm to expect
        timeout  = Validator.config['timeouts']['alarm']

        log "Activating alarm #{alarm_code_id}"
        deactivate, component_id = with_alarm_activated(task, site, alarm_code_id) do |alarm, component_id|   # raise alarm, by activating input
          log "Alarm #{alarm_code_id} is now active on component #{component_id}"

          # verify timestamp
          alarm_time = Time.parse(alarm.attributes["aTs"])
          expect(alarm_time).to be_within(1.minute).of Time.now.utc

          # test acknowledge and confirm
          log "Acknowledge alarm #{alarm_code_id}"

          collect_task = task.async do
            RSMP::AlarmCollector.new(site,
              num: 1,
              query: {
                'aCId' => alarm_code_id,
                'aSp' => /Acknowledge/i,
                'ack' => /Acknowledged/i,
                'aS' => /Active/i
              },
              timeout: timeout
            ).collect!
          end

          site.send_message RSMP::AlarmAcknowledged.new(
            'cId' => component_id,
            'aTs' => site.clock.to_s,
            'aCId' => alarm_code_id
          )
          messages = collect_task.wait
          expect(messages).to be_an(Array)
          expect(messages.first).to be_a(RSMP::Alarm)
        end
      end
    end

    # Validate that alarms can be suspended. We're using A0302 in this test.
    #
    # 1. Given the site is connected
    # 2. And the alarm is  resumed
    # 3. When we suspend the alarm
    # 4. Then we should received an alarm suspended messsage
    # 5. When we resume the alarm
    # 6. Then we should receive an alarm resumed message

    it 'A0302 can be suspended and resumed' do
      Validator::Site.connected do |task,supervisor,site|
        alarm_code_id = 'A0302'
        action = Validator.config.dig('alarms', alarm_code_id)
        skip "alarm #{alarm_code_id} is not configured" unless action
        component_id = action['component']
        skip "alarm #{alarm_code_id} has no component configured" unless component_id
        # first resume to make sure something happens when we suspend
        resume = RSMP::AlarmResume.new(
          'cId' => component_id,
          'aCId' => alarm_code_id
        )
        site.send_message resume

        # now suspend the alarm while collecting responses
        suspend = RSMP::AlarmSuspend.new(
          'mId' => RSMP::Message.make_m_id,     # generate a message id, that can be used to listen for responses
          'cId' => component_id,
          'aCId' => alarm_code_id
        )
        collect_task = task.async do
          RSMP::AlarmCollector.new(site,
            m_id: suspend.m_id,
            num: 1,
            query: {
              'cId' => component_id,
              'aCI' => alarm_code_id,
              'aSp' => 'Suspend',
              'sS' => 'suspended'
            },
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
            query: {'aCI'=>alarm_code_id,'aSp'=>'Suspend','sS'=>'notSuspended'},
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
