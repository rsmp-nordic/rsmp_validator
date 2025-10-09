module Validator::ProgrammingHelpers
	def find_alarm_programming alarm_code_id
		action = Validator.config.dig('alarm_triggers',alarm_code_id)
		skip "Alarm trigger #{alarm_code_id} not configured" unless action
		return action["input"], action["component"]
	end

	# Load a group-based program from configuration
	# @param program_id [String] Program identifier
	# @return [Validator::GroupBasedProgram] The loaded program
	def load_group_based_program(program_id)
		require_relative '../../lib/validator/group_based_program'
		program_config = Validator.config.dig('group_based_programs', program_id)
		skip "Group-based program #{program_id} not configured" unless program_config
		Validator::GroupBasedProgram.new(program_config)
	end

	# Validate a group-based program with regional and intersection constraints
	# @param program [Validator::GroupBasedProgram] Program to validate
	# @return [Array<String>] List of validation errors
	def validate_group_based_program(program)
		require_relative '../../lib/validator/constraint_validator'
		regional_config = Validator.config['regional_config']
		intersection_config = Validator.config['intersection_config']
		validator = Validator::ConstraintValidator.new(regional_config, intersection_config, program)
		validator.validate
	end

	# Get timing configuration for a signal group from a group-based program
	# @param program [Validator::GroupBasedProgram] Program
	# @param signal_group [String] Signal group ID
	# @return [Hash] Timing configuration
	def get_program_timing(program, signal_group)
		program.timing_for(signal_group)
	end

	# Check if a group-based program has detector logic for a signal group
	# @param program [Validator::GroupBasedProgram] Program
	# @param signal_group [String] Signal group ID
	# @return [Boolean] True if detector logic exists
	def has_detector_logic?(program, signal_group)
		!program.detector_logics_for(signal_group).empty?
	end
end
