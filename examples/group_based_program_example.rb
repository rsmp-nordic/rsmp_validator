#!/usr/bin/env ruby
# Example demonstrating group-based programming features
# Run: ruby examples/group_based_program_example.rb

require 'yaml'
require_relative '../lib/validator/group_based_program'
require_relative '../lib/validator/constraint_validator'

# Define regional regulatory constraints
regional_config = {
  'regulations' => {
    'minimum_green_times' => {
      'vehicle' => 5,
      'pedestrian' => 6
    },
    'maximum_green_times' => {
      'default' => 120
    }
  }
}

# Define intersection topology
intersection_config = {
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
    { 'from' => 'sg2', 'to' => 'sg1', 'min_time' => 4 }
  ],
  'detectors' => {
    'd1' => { 'type' => 'loop', 'location' => 'NS approach' },
    'd2' => { 'type' => 'button', 'location' => 'Ped crossing' }
  }
}

# Define a group-based program
program_config = {
  'id' => 'demo_actuated',
  'version' => '1.0',
  'description' => 'Demo actuated control program',
  'timing' => {
    'sg1' => { 'min_green' => 10, 'max_green' => 60 },
    'sg2' => { 'min_green' => 8, 'max_green' => 45 },
    'sg3' => { 'min_green' => 15, 'max_green' => 20 }
  },
  'detector_logics' => [
    { 'detectors' => ['d1'], 'creates_demand_for' => 'sg1', 'priority' => 5 },
    { 'detectors' => ['d2'], 'creates_demand_for' => 'sg3', 'priority' => 8 }
  ],
  'extension_rules' => [
    { 'signal_group' => 'sg1', 'type' => 'gap_out', 'gap_time' => 3, 'max_extension' => 20 }
  ],
  'objectives' => [
    { 'type' => 'minimize_delay', 'weight' => 1.0 }
  ]
}

puts "=== Group-Based Programming Example ==="
puts

# Create program instance
puts "Creating program..."
program = Validator::GroupBasedProgram.new(program_config)
puts "  ID: #{program.id}"
puts "  Version: #{program.version}"
puts "  Description: #{program.description}"
puts

# Validate program structure
puts "Validating program structure..."
errors = program.validate
if errors.empty?
  puts "  ✓ Program structure is valid"
else
  puts "  ✗ Validation errors:"
  errors.each { |e| puts "    - #{e}" }
end
puts

# Query timing
puts "Signal group timing:"
program.timing.each do |sg, timing|
  puts "  #{sg}: min=#{timing['min_green']}s, max=#{timing['max_green']}s"
end
puts

# Query detector logics
puts "Detector logics:"
program.detector_logics.each do |dl|
  puts "  #{dl['detectors'].join(', ')} → #{dl['creates_demand_for']} (priority: #{dl['priority']})"
end
puts

# Validate constraints
puts "Validating constraints..."
validator = Validator::ConstraintValidator.new(regional_config, intersection_config, program)
errors = validator.validate
if errors.empty?
  puts "  ✓ All constraints satisfied"
else
  puts "  ✗ Constraint violations:"
  errors.each { |e| puts "    - #{e}" }
end
puts

# Check conflicts
puts "Conflict matrix:"
['sg1', 'sg2', 'sg3'].each do |sg1|
  ['sg1', 'sg2', 'sg3'].each do |sg2|
    next if sg1 == sg2
    if validator.conflicts?(sg1, sg2)
      puts "  #{sg1} ⊥ #{sg2} (conflicting)"
    end
  end
end
puts

# Check intergreen times
puts "Intergreen times:"
[['sg1', 'sg2'], ['sg2', 'sg1']].each do |from_sg, to_sg|
  time = validator.min_intergreen_time(from_sg, to_sg)
  puts "  #{from_sg} → #{to_sg}: #{time}s" if time
end
puts

# Convert to hash
puts "Serializing program..."
hash = program.to_h
puts "  Hash keys: #{hash.keys.join(', ')}"
puts

puts "=== Example Complete ==="
