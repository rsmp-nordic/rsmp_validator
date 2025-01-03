module Validator::ProgrammingHelpers
	def find_alarm_programming alarm_code_id
		action = Validator.config.dig('inputs','programming')
		skip "Alarm #{alarm_code_id} is not configured" unless action

		action = action.find do |input,options|
		  options['raise_alarm'] == alarm_code_id
		end
		skip "Alarm #{alarm_code_id} is not configured" unless action

		input = action.first
		component_id = action.last['component']

		return input, component_id
	end
end
