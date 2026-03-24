module Validator
  module AlarmHelpers
    # Run a block with an alarm activated, then deactivate the alarm.
    # The device must be programmed to activate an alarm when a specific
    # input is activated, and the mapping must be configured in the test config.
    def with_alarm_activated(task, site, alarm_code_id, initial_deactivation: true)
      input_nr, component_id = find_alarm_programming(alarm_code_id)
      component_id ||= Validator.get_config('main_component')
      force_input_and_confirm site, input: input_nr, value: 'False' if initial_deactivation
      state = false
      begin
        if RSMP::Proxy.version_meets_requirement? site.core_version, '>=3.2'
          # from core 3.2 all enum matching must be match exactly
          alarm_specialization = /Issue/
          alarm_active = /Active/
          alarm_inactive = /inActive/
        else
          # before 3.2 match is done case-insensitively
          alarm_specialization = /issue/i
          alarm_active = /active/i
          alarm_inactive = /inactive/i
        end

        collect_task = task.async do  # run the collector in an async task
          collector = RSMP::AlarmCollector.new(site,
                                               num: 1,
                                               matcher: {
                                                 'cId' => component_id,
                                                 'aCId' => alarm_code_id,
                                                 'aSp' => alarm_specialization,
                                                 'aS' => alarm_active
                                               },
                                               timeout: Validator.get_config('timeouts', 'alarm'))
          collector.collect!
          collector.messages.first
        end
        force_input_and_confirm site, input: input_nr, value: 'True'
        state = true
        yield collect_task.wait, component_id

        collect_task = task.async do  # run the collector in an async task
          collector = RSMP::AlarmCollector.new(site,
                                               num: 1,
                                               matcher: {
                                                 'cId' => component_id,
                                                 'aCId' => alarm_code_id,
                                                 'aSp' => /Issue/i,
                                                 'aS' => alarm_inactive
                                               },
                                               timeout: Validator.get_config('timeouts', 'alarm'))
          collector.collect!
          collector.messages.first
        end
        force_input_and_confirm site, input: input_nr, value: 'False'
        state = false
        [collect_task.wait, component_id]
      ensure
        force_input_and_confirm site, input: input_nr, value: 'False' if state == true
      end
    end
  end
end
