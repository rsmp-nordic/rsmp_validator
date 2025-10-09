require_relative '../../lib/validator/group_based_program'

RSpec.describe Validator::GroupBasedProgram do
  describe '#initialize' do
    it 'creates a program from configuration' do
      config = {
        'id' => 'test_program_1',
        'version' => '1.0',
        'description' => 'Test actuated program',
        'timing' => {
          'sg1' => { 'min_green' => 10, 'max_green' => 60 },
          'sg2' => { 'min_green' => 8, 'max_green' => 45 }
        },
        'detector_logics' => [
          { 'detectors' => ['d1'], 'creates_demand_for' => 'sg1', 'priority' => 5 }
        ],
        'extension_rules' => [
          { 'signal_group' => 'sg1', 'type' => 'gap_out', 'gap_time' => 3 }
        ],
        'objectives' => [
          { 'type' => 'minimize_delay', 'weight' => 1.0 }
        ]
      }

      program = Validator::GroupBasedProgram.new(config)

      expect(program.id).to eq('test_program_1')
      expect(program.version).to eq('1.0')
      expect(program.description).to eq('Test actuated program')
      expect(program.timing.keys).to contain_exactly('sg1', 'sg2')
      expect(program.detector_logics.size).to eq(1)
      expect(program.extension_rules.size).to eq(1)
      expect(program.objectives.size).to eq(1)
    end

    it 'handles minimal configuration' do
      config = {
        'id' => 'minimal_program',
        'version' => '1.0'
      }

      program = Validator::GroupBasedProgram.new(config)

      expect(program.id).to eq('minimal_program')
      expect(program.timing).to be_empty
      expect(program.detector_logics).to be_empty
    end
  end

  describe '#timing_for' do
    it 'returns timing configuration for a signal group' do
      config = {
        'id' => 'test',
        'version' => '1.0',
        'timing' => {
          'sg1' => { 'min_green' => 10, 'max_green' => 60 }
        }
      }

      program = Validator::GroupBasedProgram.new(config)
      timing = program.timing_for('sg1')

      expect(timing['min_green']).to eq(10)
      expect(timing['max_green']).to eq(60)
    end

    it 'returns empty hash for undefined signal group' do
      program = Validator::GroupBasedProgram.new('id' => 'test', 'version' => '1.0')
      timing = program.timing_for('nonexistent')

      expect(timing).to eq({})
    end
  end

  describe '#detector_logics_for' do
    it 'returns detector logics for a signal group' do
      config = {
        'id' => 'test',
        'version' => '1.0',
        'detector_logics' => [
          { 'detectors' => ['d1'], 'creates_demand_for' => 'sg1', 'priority' => 5 },
          { 'detectors' => ['d2'], 'creates_demand_for' => 'sg2', 'priority' => 3 },
          { 'detectors' => ['d3'], 'creates_demand_for' => 'sg1', 'priority' => 8 }
        ]
      }

      program = Validator::GroupBasedProgram.new(config)
      logics = program.detector_logics_for('sg1')

      expect(logics.size).to eq(2)
      expect(logics.map { |l| l['detectors'] }.flatten).to contain_exactly('d1', 'd3')
    end
  end

  describe '#extension_rule_for' do
    it 'returns extension rule for a signal group' do
      config = {
        'id' => 'test',
        'version' => '1.0',
        'extension_rules' => [
          { 'signal_group' => 'sg1', 'type' => 'gap_out', 'gap_time' => 3 }
        ]
      }

      program = Validator::GroupBasedProgram.new(config)
      rule = program.extension_rule_for('sg1')

      expect(rule['type']).to eq('gap_out')
      expect(rule['gap_time']).to eq(3)
    end

    it 'returns nil for signal group without extension rule' do
      program = Validator::GroupBasedProgram.new('id' => 'test', 'version' => '1.0')
      rule = program.extension_rule_for('sg1')

      expect(rule).to be_nil
    end
  end

  describe '#validate' do
    it 'validates successfully for valid program' do
      config = {
        'id' => 'valid_program',
        'version' => '1.0',
        'timing' => {
          'sg1' => { 'min_green' => 10, 'max_green' => 60 }
        }
      }

      program = Validator::GroupBasedProgram.new(config)
      errors = program.validate

      expect(errors).to be_empty
    end

    it 'detects missing id' do
      config = { 'version' => '1.0' }
      program = Validator::GroupBasedProgram.new(config)
      errors = program.validate

      expect(errors).to include('Program must have an id')
    end

    it 'detects missing version' do
      config = { 'id' => 'test' }
      program = Validator::GroupBasedProgram.new(config)
      errors = program.validate

      expect(errors).to include('Program must have a version')
    end

    it 'detects min_green exceeding max_green' do
      config = {
        'id' => 'invalid',
        'version' => '1.0',
        'timing' => {
          'sg1' => { 'min_green' => 60, 'max_green' => 30 }
        }
      }

      program = Validator::GroupBasedProgram.new(config)
      errors = program.validate

      expect(errors.any? { |e| e.include?('min_green') && e.include?('max_green') }).to be true
    end
  end

  describe '#to_h' do
    it 'converts program to hash representation' do
      config = {
        'id' => 'test',
        'version' => '1.0',
        'description' => 'Test program',
        'timing' => { 'sg1' => { 'min_green' => 10 } }
      }

      program = Validator::GroupBasedProgram.new(config)
      hash = program.to_h

      expect(hash['id']).to eq('test')
      expect(hash['version']).to eq('1.0')
      expect(hash['description']).to eq('Test program')
      expect(hash['timing']).to eq({ 'sg1' => { 'min_green' => 10 } })
    end
  end
end
