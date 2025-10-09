module Validator
  # Represents a group-based traffic control program
  # Based on constraint programming rather than traditional phase-based programming
  # See: https://github.com/rsmp-nordic/tlc_programming/blob/main/group_based.md
  class GroupBasedProgram
    attr_reader :id, :version, :description, :timing, :detector_logics, :extension_rules, :objectives

    # Initialize a new group-based program
    # @param config [Hash] Program configuration
    def initialize(config)
      @id = config['id']
      @version = config['version']
      @description = config['description']
      @timing = config['timing'] || {}
      @detector_logics = config['detector_logics'] || []
      @extension_rules = config['extension_rules'] || []
      @objectives = config['objectives'] || []
    end

    # Get timing configuration for a signal group
    # @param signal_group [String] Signal group ID
    # @return [Hash] Timing configuration with :min_green and :max_green
    def timing_for(signal_group)
      @timing[signal_group] || {}
    end

    # Get detector logics that create demand for a signal group
    # @param signal_group [String] Signal group ID
    # @return [Array<Hash>] Detector logic configurations
    def detector_logics_for(signal_group)
      @detector_logics.select { |dl| dl['creates_demand_for'] == signal_group }
    end

    # Get extension rule for a signal group
    # @param signal_group [String] Signal group ID
    # @return [Hash, nil] Extension rule configuration
    def extension_rule_for(signal_group)
      @extension_rules.find { |rule| rule['signal_group'] == signal_group }
    end

    # Validate program structure
    # @return [Array<String>] List of validation errors, empty if valid
    def validate
      errors = []
      errors << "Program must have an id" if @id.nil? || @id.empty?
      errors << "Program must have a version" if @version.nil? || @version.empty?
      
      # Validate timing constraints
      @timing.each do |sg, timing|
        if timing['min_green'] && timing['max_green']
          if timing['min_green'] > timing['max_green']
            errors << "Signal group #{sg}: min_green (#{timing['min_green']}) cannot exceed max_green (#{timing['max_green']})"
          end
        end
      end

      errors
    end

    # Convert program to hash representation
    # @return [Hash] Program configuration
    def to_h
      {
        'id' => @id,
        'version' => @version,
        'description' => @description,
        'timing' => @timing,
        'detector_logics' => @detector_logics,
        'extension_rules' => @extension_rules,
        'objectives' => @objectives
      }
    end
  end
end
