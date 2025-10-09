RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::StatusHelpers
  include Validator::CommandHelpers
  include Validator::ProgrammingHelpers

  describe "Group-Based Programming" do
    # Verify that a group-based program can be loaded from configuration
    #
    # 1. Given the site is connected
    # 2. When we load a group-based program from configuration
    # 3. Then the program should be loaded successfully
    # 4. And the program should have valid structure
    specify 'program is loaded from configuration', sxl: '>=1.0.15' do |example|
      skip "No group-based programs configured" unless Validator.config['group_based_programs']
      
      program_id = Validator.config['group_based_programs'].keys.first
      program = load_group_based_program(program_id)
      
      expect(program).to be_a(Validator::GroupBasedProgram)
      expect(program.id).not_to be_nil
      expect(program.version).not_to be_nil
      
      errors = program.validate
      expect(errors).to be_empty, "Program validation errors: #{errors.join(', ')}"
    end

    # Verify that a group-based program satisfies all constraints
    #
    # 1. Given the site is connected
    # 2. When we load a group-based program
    # 3. And validate it against regional and intersection constraints
    # 4. Then validation should pass with no errors
    specify 'program satisfies constraints', sxl: '>=1.0.15' do |example|
      skip "No group-based programs configured" unless Validator.config['group_based_programs']
      skip "Regional or intersection config not provided" unless Validator.config['regional_config'] && Validator.config['intersection_config']
      
      program_id = Validator.config['group_based_programs'].keys.first
      program = load_group_based_program(program_id)
      
      errors = validate_group_based_program(program)
      expect(errors).to be_empty, "Constraint validation errors: #{errors.join(', ')}"
    end

    # Verify that program timing constraints are accessible
    #
    # 1. Given a group-based program is loaded
    # 2. When we query timing for signal groups
    # 3. Then we should get valid timing configurations
    specify 'program timing is accessible', sxl: '>=1.0.15' do |example|
      skip "No group-based programs configured" unless Validator.config['group_based_programs']
      
      program_id = Validator.config['group_based_programs'].keys.first
      program = load_group_based_program(program_id)
      
      signal_groups = Validator.get_config('components', 'signal_group')&.keys || []
      skip "No signal groups configured" if signal_groups.empty?
      
      signal_groups.each do |sg|
        timing = get_program_timing(program, sg)
        
        # If timing is defined, validate it
        if timing['min_green'] && timing['max_green']
          expect(timing['min_green']).to be > 0
          expect(timing['max_green']).to be >= timing['min_green']
        end
      end
    end

    # Verify that detector logics are properly configured
    #
    # 1. Given a group-based program is loaded
    # 2. When we check detector logic configuration
    # 3. Then detector logics should reference valid signal groups and detectors
    specify 'detector logics are configured', sxl: '>=1.0.15' do |example|
      skip "No group-based programs configured" unless Validator.config['group_based_programs']
      
      program_id = Validator.config['group_based_programs'].keys.first
      program = load_group_based_program(program_id)
      
      signal_groups = Validator.get_config('components', 'signal_group')&.keys || []
      
      program.detector_logics.each do |dl|
        # Verify signal group reference
        sg = dl['creates_demand_for']
        if sg
          expect(signal_groups).to include(sg), 
            "Detector logic references undefined signal group: #{sg}"
        end
        
        # Verify detector references if detectors are configured
        if dl['detectors'] && Validator.config['intersection_config']
          defined_detectors = Validator.config.dig('intersection_config', 'detectors')&.keys || []
          dl['detectors'].each do |detector|
            expect(defined_detectors).to include(detector),
              "Detector logic references undefined detector: #{detector}"
          end
        end
      end
    end

    # Verify that extension rules reference valid signal groups
    #
    # 1. Given a group-based program is loaded
    # 2. When we check extension rules
    # 3. Then all extension rules should reference defined signal groups
    specify 'extension rules reference valid signal groups', sxl: '>=1.0.15' do |example|
      skip "No group-based programs configured" unless Validator.config['group_based_programs']
      
      program_id = Validator.config['group_based_programs'].keys.first
      program = load_group_based_program(program_id)
      
      signal_groups = Validator.get_config('components', 'signal_group')&.keys || []
      
      program.extension_rules.each do |rule|
        sg = rule['signal_group']
        expect(signal_groups).to include(sg),
          "Extension rule references undefined signal group: #{sg}"
      end
    end

    # Verify that program can be converted to hash representation
    #
    # 1. Given a group-based program is loaded
    # 2. When we convert it to a hash
    # 3. Then the hash should contain all program data
    # 4. And we should be able to recreate the program from the hash
    specify 'program can be serialized to hash', sxl: '>=1.0.15' do |example|
      skip "No group-based programs configured" unless Validator.config['group_based_programs']
      
      program_id = Validator.config['group_based_programs'].keys.first
      program = load_group_based_program(program_id)
      
      hash = program.to_h
      
      expect(hash).to be_a(Hash)
      expect(hash['id']).to eq(program.id)
      expect(hash['version']).to eq(program.version)
      expect(hash['timing']).to eq(program.timing)
      expect(hash['detector_logics']).to eq(program.detector_logics)
      
      # Recreate program from hash
      program2 = Validator::GroupBasedProgram.new(hash)
      expect(program2.id).to eq(program.id)
      expect(program2.version).to eq(program.version)
    end
  end
end
