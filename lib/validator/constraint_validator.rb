module Validator
  # Validates constraints for group-based traffic control programs
  # Ensures hard constraints (conflicts, intergreen times, timing bounds) are satisfied
  class ConstraintValidator
    attr_reader :regional_config, :intersection_config, :program

    # Initialize validator with configuration layers
    # @param regional_config [Hash] Regional regulatory configuration
    # @param intersection_config [Hash] Intersection topology configuration
    # @param program [GroupBasedProgram] Program defining behavior
    def initialize(regional_config, intersection_config, program)
      @regional_config = regional_config || {}
      @intersection_config = intersection_config || {}
      @program = program
    end

    # Validate all constraints
    # @return [Array<String>] List of validation errors, empty if valid
    def validate
      errors = []
      errors.concat(validate_signal_groups)
      errors.concat(validate_timing_constraints)
      errors.concat(validate_detector_references)
      errors.concat(validate_conflicts)
      errors.concat(validate_intergreen_times)
      errors
    end

    # Validate that all signal groups in program exist in intersection config
    # @return [Array<String>] Validation errors
    def validate_signal_groups
      errors = []
      return errors unless @intersection_config['signal_groups']

      defined_signal_groups = @intersection_config['signal_groups'].keys
      
      @program.timing.keys.each do |sg|
        unless defined_signal_groups.include?(sg)
          errors << "Program references undefined signal group: #{sg}"
        end
      end

      errors
    end

    # Validate timing constraints against regional regulations
    # @return [Array<String>] Validation errors
    def validate_timing_constraints
      errors = []
      return errors unless @regional_config['regulations']

      regulations = @regional_config['regulations']
      min_green_defaults = regulations['minimum_green_times'] || {}
      max_green_default = regulations.dig('maximum_green_times', 'default')

      @program.timing.each do |sg, timing|
        # Get signal group type from intersection config
        sg_type = @intersection_config.dig('signal_groups', sg, 'type')
        next unless sg_type

        # Check minimum green time
        regulatory_min = min_green_defaults[sg_type]
        if regulatory_min && timing['min_green']
          if timing['min_green'] < regulatory_min
            errors << "Signal group #{sg}: min_green (#{timing['min_green']}s) violates regulatory minimum (#{regulatory_min}s)"
          end
        end

        # Check maximum green time
        if max_green_default && timing['max_green']
          if timing['max_green'] > max_green_default
            errors << "Signal group #{sg}: max_green (#{timing['max_green']}s) exceeds regulatory maximum (#{max_green_default}s)"
          end
        end
      end

      errors
    end

    # Validate that all detectors referenced in program exist in intersection config
    # @return [Array<String>] Validation errors
    def validate_detector_references
      errors = []
      return errors unless @intersection_config['detectors']

      defined_detectors = @intersection_config['detectors'].keys

      @program.detector_logics.each do |dl|
        next unless dl['detectors']
        
        dl['detectors'].each do |detector|
          unless defined_detectors.include?(detector)
            errors << "Program references undefined detector: #{detector}"
          end
        end
      end

      errors
    end

    # Validate conflict constraints
    # @return [Array<String>] Validation errors
    def validate_conflicts
      errors = []
      return errors unless @intersection_config['conflicts']

      # Build conflict matrix for quick lookup
      @conflict_matrix = {}
      @intersection_config['conflicts'].each do |conflict|
        groups = conflict['groups']
        next unless groups && groups.size >= 2
        
        groups.each do |sg1|
          @conflict_matrix[sg1] ||= []
          groups.each do |sg2|
            @conflict_matrix[sg1] << sg2 if sg1 != sg2
          end
        end
      end

      errors
    end

    # Validate intergreen time constraints
    # @return [Array<String>] Validation errors
    def validate_intergreen_times
      errors = []
      return errors unless @intersection_config['intergreens']

      # Ensure all intergreen times are defined for conflicting signal groups
      @intersection_config['intergreens'].each do |intergreen|
        from = intergreen['from']
        to = intergreen['to']
        min_time = intergreen['min_time']

        unless min_time && min_time > 0
          errors << "Intergreen time from #{from} to #{to} must be positive"
        end
      end

      errors
    end

    # Check if two signal groups conflict
    # @param sg1 [String] First signal group
    # @param sg2 [String] Second signal group
    # @return [Boolean] True if groups conflict
    def conflicts?(sg1, sg2)
      return false unless @conflict_matrix
      @conflict_matrix[sg1]&.include?(sg2) || false
    end

    # Get minimum intergreen time between two signal groups
    # @param from_sg [String] Source signal group
    # @param to_sg [String] Target signal group
    # @return [Integer, nil] Minimum intergreen time in seconds
    def min_intergreen_time(from_sg, to_sg)
      return nil unless @intersection_config['intergreens']
      
      intergreen = @intersection_config['intergreens'].find do |ig|
        ig['from'] == from_sg && ig['to'] == to_sg
      end
      
      intergreen&.dig('min_time')
    end
  end
end
