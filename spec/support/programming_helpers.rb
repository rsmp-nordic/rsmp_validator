module Validator::ProgrammingHelpers
	def find_alarm_programming alarm_code_id
		action = Validator.config.dig('alarm_triggers',alarm_code_id)
		skip "Alarm trigger #{alarm_code_id} not configured" unless action
		return action["input"], action["component"]
	end
end
