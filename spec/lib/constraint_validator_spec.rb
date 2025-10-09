require_relative '../../lib/validator/group_based_program'
require_relative '../../lib/validator/constraint_validator'

RSpec.describe Validator::ConstraintValidator do
  let(:regional_config) do
    {
      'regulations' => {
        'yellow_times' => { 'default' => 3 },
        'all_red_times' => { 'default' => 2 },
        'minimum_green_times' => {
          'vehicle' => 5,
          'pedestrian' => 6
        },
        'maximum_green_times' => {
          'default' => 120
        }
      }
    }
  end

  let(:intersection_config) do
    {
      'signal_groups' => {
        'sg1' => { 'type' => 'vehicle', 'description' => 'North-South' },
        'sg2' => { 'type' => 'vehicle', 'description' => 'East-West' },
        'sg3' => { 'type' => 'pedestrian', 'description' => 'Pedestrian' }
      },
      'conflicts' => [
        { 'groups' => ['sg1', 'sg2'], 'reason' => 'Perpendicular' },
        { 'groups' => ['sg1', 'sg3'], 'reason' => 'Crossing' }
      ],
      'intergreens' => [
        { 'from' => 'sg1', 'to' => 'sg2', 'min_time' => 4 },
        { 'from' => 'sg2', 'to' => 'sg1', 'min_time' => 4 },
        { 'from' => 'sg1', 'to' => 'sg3', 'min_time' => 3 }
      ],
      'detectors' => {
        'd1' => { 'type' => 'loop', 'location' => 'NS approach' },
        'd2' => { 'type' => 'button', 'location' => 'Ped crossing' }
      }
    }
  end

  let(:valid_program_config) do
    {
      'id' => 'test_program',
      'version' => '1.0',
      'timing' => {
        'sg1' => { 'min_green' => 10, 'max_green' => 60 },
        'sg2' => { 'min_green' => 8, 'max_green' => 45 },
        'sg3' => { 'min_green' => 15, 'max_green' => 20 }
      },
      'detector_logics' => [
        { 'detectors' => ['d1'], 'creates_demand_for' => 'sg1' },
        { 'detectors' => ['d2'], 'creates_demand_for' => 'sg3' }
      ]
    }
  end

  describe '#validate' do
    it 'validates a correct program' do
      program = Validator::GroupBasedProgram.new(valid_program_config)
      validator = Validator::ConstraintValidator.new(regional_config, intersection_config, program)
      errors = validator.validate

      expect(errors).to be_empty
    end
  end

  describe '#validate_signal_groups' do
    it 'detects undefined signal groups' do
      config = valid_program_config.dup
      config['timing']['sg_undefined'] = { 'min_green' => 10 }
      
      program = Validator::GroupBasedProgram.new(config)
      validator = Validator::ConstraintValidator.new(regional_config, intersection_config, program)
      errors = validator.validate_signal_groups

      expect(errors.any? { |e| e.include?('sg_undefined') }).to be true
    end

    it 'passes when all signal groups are defined' do
      program = Validator::GroupBasedProgram.new(valid_program_config)
      validator = Validator::ConstraintValidator.new(regional_config, intersection_config, program)
      errors = validator.validate_signal_groups

      expect(errors).to be_empty
    end
  end

  describe '#validate_timing_constraints' do
    it 'detects min_green below regulatory minimum' do
      config = valid_program_config.dup
      config['timing']['sg1']['min_green'] = 3  # Below vehicle minimum of 5
      
      program = Validator::GroupBasedProgram.new(config)
      validator = Validator::ConstraintValidator.new(regional_config, intersection_config, program)
      errors = validator.validate_timing_constraints

      expect(errors.any? { |e| e.include?('violates regulatory minimum') }).to be true
    end

    it 'detects max_green above regulatory maximum' do
      config = valid_program_config.dup
      config['timing']['sg1']['max_green'] = 150  # Above maximum of 120
      
      program = Validator::GroupBasedProgram.new(config)
      validator = Validator::ConstraintValidator.new(regional_config, intersection_config, program)
      errors = validator.validate_timing_constraints

      expect(errors.any? { |e| e.include?('exceeds regulatory maximum') }).to be true
    end

    it 'passes when timing is within regulatory bounds' do
      program = Validator::GroupBasedProgram.new(valid_program_config)
      validator = Validator::ConstraintValidator.new(regional_config, intersection_config, program)
      errors = validator.validate_timing_constraints

      expect(errors).to be_empty
    end
  end

  describe '#validate_detector_references' do
    it 'detects undefined detectors' do
      config = valid_program_config.dup
      config['detector_logics'] << { 'detectors' => ['d_undefined'], 'creates_demand_for' => 'sg1' }
      
      program = Validator::GroupBasedProgram.new(config)
      validator = Validator::ConstraintValidator.new(regional_config, intersection_config, program)
      errors = validator.validate_detector_references

      expect(errors.any? { |e| e.include?('d_undefined') }).to be true
    end

    it 'passes when all detectors are defined' do
      program = Validator::GroupBasedProgram.new(valid_program_config)
      validator = Validator::ConstraintValidator.new(regional_config, intersection_config, program)
      errors = validator.validate_detector_references

      expect(errors).to be_empty
    end
  end

  describe '#conflicts?' do
    it 'identifies conflicting signal groups' do
      program = Validator::GroupBasedProgram.new(valid_program_config)
      validator = Validator::ConstraintValidator.new(regional_config, intersection_config, program)
      validator.validate_conflicts  # Build conflict matrix

      expect(validator.conflicts?('sg1', 'sg2')).to be true
      expect(validator.conflicts?('sg1', 'sg3')).to be true
    end

    it 'identifies non-conflicting signal groups' do
      program = Validator::GroupBasedProgram.new(valid_program_config)
      validator = Validator::ConstraintValidator.new(regional_config, intersection_config, program)
      validator.validate_conflicts  # Build conflict matrix

      expect(validator.conflicts?('sg2', 'sg3')).to be false
    end
  end

  describe '#min_intergreen_time' do
    it 'returns minimum intergreen time between signal groups' do
      program = Validator::GroupBasedProgram.new(valid_program_config)
      validator = Validator::ConstraintValidator.new(regional_config, intersection_config, program)

      expect(validator.min_intergreen_time('sg1', 'sg2')).to eq(4)
      expect(validator.min_intergreen_time('sg1', 'sg3')).to eq(3)
    end

    it 'returns nil for undefined intergreen time' do
      program = Validator::GroupBasedProgram.new(valid_program_config)
      validator = Validator::ConstraintValidator.new(regional_config, intersection_config, program)

      expect(validator.min_intergreen_time('sg2', 'sg3')).to be_nil
    end
  end

  describe '#validate_intergreen_times' do
    it 'detects invalid intergreen times' do
      bad_intersection_config = intersection_config.dup
      bad_intersection_config['intergreens'] = [
        { 'from' => 'sg1', 'to' => 'sg2', 'min_time' => 0 }
      ]
      
      program = Validator::GroupBasedProgram.new(valid_program_config)
      validator = Validator::ConstraintValidator.new(regional_config, bad_intersection_config, program)
      errors = validator.validate_intergreen_times

      expect(errors.any? { |e| e.include?('must be positive') }).to be true
    end

    it 'passes when intergreen times are valid' do
      program = Validator::GroupBasedProgram.new(valid_program_config)
      validator = Validator::ConstraintValidator.new(regional_config, intersection_config, program)
      errors = validator.validate_intergreen_times

      expect(errors).to be_empty
    end
  end
end
