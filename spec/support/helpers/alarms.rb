module Validator
  module Helpers
    module Alarms
      include Input

      # Run a block with an alarm activated, then deactivate the alarm.
      # The device must be programmed to activate an alarm when a specific
      # input is activated, and the mapping must be configured in the test config.
      def with_alarm_activated(task, site, alarm_code_id, initial_deactivation: true, &block)
        input_nr, component_id = find_alarm_programming(alarm_code_id)
        component_id ||= Validator.get_config('main_component')
        force_input_and_confirm site, input: input_nr, value: 'False' if initial_deactivation
        run_alarm_lifecycle(task, site, alarm_code_id, component_id, input_nr, &block)
      end

      private

      def run_alarm_lifecycle(task, site, alarm_code_id, component_id, input_nr)
        specialization, alarm_active, alarm_inactive = build_alarm_matchers(site)
        timeout = Validator.get_config('timeouts', 'alarm')
        state = false
        begin
          matcher = { 'cId' => component_id, 'aCId' => alarm_code_id,
                      'aSp' => specialization, 'aS' => alarm_active }
          collect_task = start_alarm_collector(task, site, matcher, timeout)
          force_input_and_confirm site, input: input_nr, value: 'True'
          state = true
          yield collect_task.wait, component_id

          matcher = { 'cId' => component_id, 'aCId' => alarm_code_id,
                      'aSp' => /Issue/i, 'aS' => alarm_inactive }
          collect_task = start_alarm_collector(task, site, matcher, timeout)
          force_input_and_confirm site, input: input_nr, value: 'False'
          state = false
          [collect_task.wait, component_id]
        ensure
          force_input_and_confirm site, input: input_nr, value: 'False' if state == true
        end
      end

      def build_alarm_matchers(site)
        if RSMP::Proxy.version_meets_requirement? site.core_version, '>=3.2'
          # from core 3.2 all enum matching must match exactly
          [/Issue/, /Active/, /inActive/]
        else
          # before 3.2 match is done case-insensitively
          [/issue/i, /active/i, /inactive/i]
        end
      end

      def start_alarm_collector(task, site, matcher, timeout)
        task.async do
          collector = RSMP::AlarmCollector.new(site, num: 1, matcher: matcher, timeout: timeout)
          collector.collect!
          collector.messages.first
        end
      end

      def find_alarm_programming(alarm_code_id)
        action = Validator.config.dig('alarm_triggers', alarm_code_id)
        skip "Alarm trigger #{alarm_code_id} not configured" unless action
        [action['input'], action['component']]
      end
    end
  end
end
