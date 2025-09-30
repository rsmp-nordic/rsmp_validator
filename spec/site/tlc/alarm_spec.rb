RSpec.describe Site::Tlc::Alarm do
  include Validator::CommandHelpers
  include Validator::StatusHelpers
  include Validator::ProgrammingHelpers

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

    specify 'Alarm A0302 is raised when input is activated', :programming, sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        alarm_code_id = 'A0302'
        prepare task, site
        def verify_timestamp(alarm, duration = 1.minute)
          alarm_time = Time.parse(alarm.attributes['aTs'])
          expect(alarm_time).to be_within(duration).of Time.now.utc
        end
        # Raise alarm by activating input
        deactivated, component_id = with_alarm_activated(task, site, alarm_code_id) do |alarm, component_id|
          verify_timestamp alarm
          log "Alarm #{alarm_code_id} is now Active on component #{component_id}"
        end
        verify_timestamp deactivated
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
    # 3. Then we should receive an unacknowledged alarm issue
    # 4. When we acknowledge the alarm
    # 5. Then we should receive an acknowledged alarm issue

    specify 'A0302 can be acknowledged', :programming, sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        alarm_code_id = 'A0302' # what alarm to expect
        timeout = Validator.get_config('timeouts', 'alarm')

        log "Activating alarm #{alarm_code_id}"
        with_alarm_activated(task, site, alarm_code_id) do |alarm, component_id| # raise alarm, by activating input
          log "Alarm #{alarm_code_id} is now active on component #{component_id}"

          # verify timestamp
          alarm_time = Time.parse(alarm.attributes['aTs'])
          expect(alarm_time).to be_within(1.minute).of Time.now.utc

          # verify that the alarm is not acknowledged when initially raised
          ack_message = "Alarm should not be acknowledged when raised, got: #{alarm.attributes['ack']}"
          expect(alarm.attributes['ack']).to match(/notAcknowledged/i), ack_message
          log "Verified alarm #{alarm_code_id} is correctly not acknowledged when raised"

          # test acknowledge and confirm
          log "Acknowledge alarm #{alarm_code_id}"

          collect_task = task.async do
            RSMP::AlarmCollector.new(site,
                                     num: 1,
                                     matcher: {
                                       'aCId' => alarm_code_id,
                                       'aSp' => /Acknowledge/i,
                                       'ack' => /Acknowledged/i,
                                       'aS' => /Active/i
                                     },
                                     timeout: timeout).collect!
          end

          site.send_message RSMP::AlarmAcknowledge.new(
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
    # 2. And the alarm is resumed
    # 3. When we suspend the alarm
    # 4. Then we should received an alarm suspended messsage
    # 5. When we resume the alarm
    # 6. Then we should receive an alarm resumed message

    # Validate that alarm timestamps are different when alarm turns active vs inactive.
    #
    # This test verifies RSMP 3.1.4+ behavior where the alarm timestamp (aTs) 
    # represents when the alarm changes status, ensuring we can determine
    # the duration of an alarm even if it turns inactive during communication interruption.
    #
    # In RSMP 3.1.4+, the alarm timestamp should be different between active and inactive states.
    #
    # 1. Given the site is connected
    # 2. When we trigger an alarm by activating an input
    # 3. Then we should receive an alarm with timestamp representing when it turned active
    # 4. When we deactivate the input
    # 5. Then we should receive an alarm with a different timestamp representing when it turned inactive
    # 6. And the timestamps should be different to distinguish between active and inactive events

    specify 'A0302 has different timestamps for active and inactive states', :programming, sxl: '>=1.0.7', core: '>=3.1.4' do |example|
      Validator::Site.connected do |task,supervisor,site|
        alarm_code_id = 'A0302'
        prepare task, site
        
        log "Testing alarm #{alarm_code_id} timestamp differences between active/inactive states"
        
        active_timestamp = nil
        inactive_timestamp = nil
        
        deactivated, component_id = with_alarm_activated(task, site, alarm_code_id) do |alarm, component_id|
          # capture active timestamp
          active_timestamp = Time.parse(alarm.attributes["aTs"])
          log "Alarm #{alarm_code_id} is now Active on component #{component_id} at #{active_timestamp}"
          
          # verify active timestamp is close to now
          expect(active_timestamp).to be_within(1.minute).of Time.now.utc
        end
        
        # capture inactive timestamp
        inactive_timestamp = Time.parse(deactivated.attributes["aTs"])
        log "Alarm #{alarm_code_id} is now Inactive on component #{component_id} at #{inactive_timestamp}"
        
        # verify inactive timestamp is close to now
        expect(inactive_timestamp).to be_within(1.minute).of Time.now.utc
        
        # verify timestamps are different - this is the core requirement
        expect(inactive_timestamp).not_to eq(active_timestamp), 
          "Active and inactive timestamps should be different. Active: #{active_timestamp}, Inactive: #{inactive_timestamp}"
        
        # verify inactive timestamp is after active timestamp (logical sequence)
        expect(inactive_timestamp).to be > active_timestamp,
          "Inactive timestamp should be after active timestamp. Active: #{active_timestamp}, Inactive: #{inactive_timestamp}"
        
        log "Verified alarm #{alarm_code_id} has different timestamps: Active=#{active_timestamp}, Inactive=#{inactive_timestamp}"
      end
    end

    # Validate alarm timestamp behavior in pre-3.1.4 versions.
    #
    # This test verifies pre-RSMP 3.1.4 behavior where the alarm timestamp (aTs)
    # only represented when an alarm turned active, not when it changed status.
    #
    # In pre-3.1.4 versions, the alarm timestamp may be the same for both 
    # active and inactive states, since it only tracked when the alarm first became active.
    #
    # 1. Given the site is connected
    # 2. When we trigger an alarm by activating an input
    # 3. Then we should receive an alarm with timestamp representing when it turned active
    # 4. When we deactivate the input
    # 5. Then we should receive an alarm indicating inactive state
    # 6. And the timestamps may be the same (reflecting original active time)

    specify 'A0302 alarm timestamps in pre-3.1.4 versions', :programming, sxl: '>=1.0.7', core: '<3.1.4' do |example|
      Validator::Site.connected do |task,supervisor,site|
        alarm_code_id = 'A0302'
        prepare task, site
        
        log "Testing alarm #{alarm_code_id} timestamp behavior in pre-3.1.4 versions"
        
        active_timestamp = nil
        inactive_timestamp = nil
        
        deactivated, component_id = with_alarm_activated(task, site, alarm_code_id) do |alarm, component_id|
          # capture active timestamp
          active_timestamp = Time.parse(alarm.attributes["aTs"])
          log "Alarm #{alarm_code_id} is now Active on component #{component_id} at #{active_timestamp}"
          
          # verify active timestamp is close to now
          expect(active_timestamp).to be_within(1.minute).of Time.now.utc
        end
        
        # capture inactive timestamp
        inactive_timestamp = Time.parse(deactivated.attributes["aTs"])
        log "Alarm #{alarm_code_id} is now Inactive on component #{component_id} at #{inactive_timestamp}"
        
        # verify inactive timestamp is close to now
        expect(inactive_timestamp).to be_within(1.minute).of Time.now.utc
        
        # In pre-3.1.4 versions, timestamps may be the same since they only track when alarm became active
        # We just verify that we receive both active and inactive states, without requiring different timestamps
        log "Pre-3.1.4 behavior: Active=#{active_timestamp}, Inactive=#{inactive_timestamp}"
        log "Successfully received both active and inactive alarm states"
      end
    end

    it 'A0302 can be suspended and resumed' do
      Validator::SiteTester.connected do |task, _supervisor, site|
        alarm_code_id = 'A0302'
        _, component_id = find_alarm_programming(alarm_code_id)

        # first resume alarm to make sure something happens when we suspend
        resume_alarm site, task, c_id: component_id, a_c_id: alarm_code_id, collect: false

        begin
          # suspend alarm
          _, response = suspend_alarm site, task, c_id: component_id, a_c_id: alarm_code_id, collect: true
          expect(response).to be_a(RSMP::AlarmSuspended)

          # resume alarm
          _, response = resume_alarm site, task, c_id: component_id, a_c_id: alarm_code_id, collect: true
          expect(response).to be_a(RSMP::AlarmResumed)
        ensure
          # always end with resuming alarm
          resume_alarm site, task, c_id: component_id, a_c_id: alarm_code_id, collect: false
        end
      end
    end
  end
end
