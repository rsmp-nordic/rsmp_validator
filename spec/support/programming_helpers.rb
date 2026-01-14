# frozen_string_literal: true

module Validator
  module ProgrammingHelpers
    def find_alarm_programming(alarm_code_id)
      action = Validator.config.dig('alarm_triggers', alarm_code_id)
      skip "Alarm trigger #{alarm_code_id} not configured" unless action
      [action['input'], action['component']]
    end
  end
end
