module Validator
  module Helpers
    # Helper methods for testing RSMP alarm behaviour.
    module Alarms
      include Input

      def with_alarm_activated(site_proxy, alarm_code_id, initial_deactivation: true, &block)
        input_nr, component_id = find_alarm_programming(alarm_code_id)
        component_id ||= Validator.get_config('main_component')
        force_input_and_confirm site_proxy, input: input_nr, value: 'False' if initial_deactivation
        run_alarm_lifecycle(site_proxy, alarm_code_id, component_id, input_nr, &block)
      end

      private

      def run_alarm_lifecycle(site_proxy, alarm_code_id, component_id, input_nr)
        specialization, alarm_active, alarm_inactive = build_alarm_matchers(site_proxy)
        timeout = Validator.get_config('timeouts', 'alarm')
        state = false
        begin
          matcher = { 'cId' => component_id, 'aCId' => alarm_code_id,
                      'aSp' => specialization, 'aS' => alarm_active }
          collect_task = start_alarm_collector(site_proxy, matcher, timeout)
          force_input_and_confirm site_proxy, input: input_nr, value: 'True'
          state = true
          yield collect_task.wait, component_id

          matcher = { 'cId' => component_id, 'aCId' => alarm_code_id,
                      'aSp' => /Issue/i, 'aS' => alarm_inactive }
          collect_task = start_alarm_collector(site_proxy, matcher, timeout)
          force_input_and_confirm site_proxy, input: input_nr, value: 'False'
          state = false
          [collect_task.wait, component_id]
        ensure
          force_input_and_confirm site_proxy, input: input_nr, value: 'False' if state == true
        end
      end

      def build_alarm_matchers(site_proxy)
        if RSMP::Proxy.version_meets_requirement? site_proxy.core_version, '>=3.2'
          [/Issue/, /Active/, /inActive/]
        else
          [/issue/i, /active/i, /inactive/i]
        end
      end

      def start_alarm_collector(site_proxy, matcher, timeout)
        Async::Task.current.async do
          collector = RSMP::AlarmCollector.new(site_proxy, num: 1, matcher: matcher, timeout: timeout)
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
