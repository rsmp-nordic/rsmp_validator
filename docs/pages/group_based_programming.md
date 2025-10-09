---
layout: default
title: Group-Based Programming
nav_order: 6
permalink: /group-based-programming/
---

# Group-Based Programming

The RSMP Validator supports testing of **group-based traffic control programs**, a modern approach to traffic light control based on constraint programming rather than traditional phase-based programming.

## Overview

Group-based programming allows traffic engineers to specify **what must not happen** (conflicts, safety rules) and **what should happen** (service requirements, priorities), allowing the controller to dynamically find optimal signal timing.

Instead of defining fixed phases and transitions, you define:
- **Hard constraints**: Safety rules that must never be violated (conflicts, intergreen times, timing bounds)
- **Soft constraints**: Optimization objectives to maximize (minimize delays, stops, etc.)

For complete details, see the [Group-Based Programming Specification](https://github.com/rsmp-nordic/tlc_programming/blob/main/group_based.md).

## Configuration Layers

Group-based programs are organized into three configuration layers:

### 1. Regional Configuration
Contains regulatory constraints that apply to all intersections in a region:
- Yellow times
- All-red times
- Minimum/maximum green times by signal type
- Other regulatory requirements

### 2. Intersection Configuration  
Describes the physical topology of the intersection:
- Signal groups and their types
- Conflict matrix (which groups cannot be green simultaneously)
- Intergreen times (clearance times between conflicting movements)
- Detector locations and types

### 3. Program
Defines operational behavior within the constraints:
- Timing parameters (min/max green times per signal group)
- Detector logics (how detectors create demand)
- Extension rules (gap-out, max extension)
- Optimization objectives

## Configuration Example

```yaml
# Regional Configuration - Regulatory constraints
regional_config:
  region: "sweden_stockholm"
  version: "2024.1"
  regulations:
    yellow_times:
      default: 3      # seconds
    all_red_times:
      default: 2      # seconds
    minimum_green_times:
      vehicle: 5      # seconds
      pedestrian: 6
    maximum_green_times:
      default: 120    # seconds

# Intersection Configuration - Physical topology
intersection_config:
  id: "main_street_oak_ave"
  signal_groups:
    sg1:
      description: "North-South through traffic"
      type: "vehicle"
    sg2:
      description: "East-West through traffic"
      type: "vehicle"
    sg3:
      description: "Pedestrian crossing"
      type: "pedestrian"
  
  conflicts:
    - groups: [sg1, sg2]
      reason: "Perpendicular traffic flows"
    - groups: [sg1, sg3]
      reason: "Pedestrian crossing"
  
  intergreens:
    - from: sg1
      to: sg2
      min_time: 4
    - from: sg2
      to: sg1
      min_time: 4
      
  detectors:
    d1: { type: "loop", location: "NS approach 50m" }
    d2: { type: "button", location: "Ped crossing" }

# Group-Based Program
group_based_programs:
  actuated_v1:
    id: "main_intersection_actuated_v1"
    version: "1.0"
    description: "Vehicle-actuated control"
    
    timing:
      sg1:
        min_green: 10      # within regulatory limits
        max_green: 60
      sg2:
        min_green: 8
        max_green: 45
      sg3:
        min_green: 15
        max_green: 20
    
    detector_logics:
      - detectors: [d1]
        creates_demand_for: sg1
        priority: 5
      - detectors: [d2]
        creates_demand_for: sg3
        priority: 8       # pedestrians get higher priority
    
    extension_rules:
      - signal_group: sg1
        type: "gap_out"
        gap_time: 3
        max_extension: 20
    
    objectives:
      - type: "minimize_delay"
        weight: 1.0
```

## Using Group-Based Programs in Tests

The validator provides helper methods for working with group-based programs:

```ruby
# Load a program from configuration
program = load_group_based_program('actuated_v1')

# Validate program against constraints
errors = validate_group_based_program(program)

# Get timing for a signal group
timing = get_program_timing(program, 'sg1')
# => { 'min_green' => 10, 'max_green' => 60 }

# Check if detector logic exists
has_detector_logic?(program, 'sg1')  # => true
```

## Testing Group-Based Programs

The validator includes tests to verify:

1. **Program structure**: Valid ID, version, and configuration
2. **Constraint satisfaction**: All hard constraints are met
3. **Timing bounds**: Min/max green times within regulatory limits
4. **Signal group references**: All referenced groups exist
5. **Detector references**: All referenced detectors exist
6. **Conflict constraints**: Conflicting groups properly defined
7. **Intergreen times**: Clearance times properly configured

To run the tests:

```bash
SITE_CONFIG=config/group_based_program_example.yaml bundle exec rspec spec/site/tlc/group_based_program_spec.rb
```

## Data Structures

### GroupBasedProgram Class

Represents a complete group-based program:

```ruby
program = Validator::GroupBasedProgram.new(config)
program.id              # => "main_intersection_actuated_v1"
program.version         # => "1.0"
program.timing          # => { 'sg1' => {...}, 'sg2' => {...} }
program.detector_logics # => [...]
program.extension_rules # => [...]
program.objectives      # => [...]

# Get timing for specific signal group
program.timing_for('sg1')  # => { 'min_green' => 10, 'max_green' => 60 }

# Get detector logics for signal group
program.detector_logics_for('sg1')  # => [...]

# Get extension rule for signal group
program.extension_rule_for('sg1')  # => { 'type' => 'gap_out', ... }

# Validate program structure
errors = program.validate  # => []

# Convert to hash
hash = program.to_h
```

### ConstraintValidator Class

Validates programs against regional and intersection constraints:

```ruby
validator = Validator::ConstraintValidator.new(
  regional_config, 
  intersection_config, 
  program
)

# Validate all constraints
errors = validator.validate  # => []

# Check if groups conflict
validator.conflicts?('sg1', 'sg2')  # => true

# Get minimum intergreen time
validator.min_intergreen_time('sg1', 'sg2')  # => 4
```

## Benefits

Group-based programming provides several advantages:

1. **Safety**: Hard constraints ensure safety is never violated
2. **Flexibility**: Easy to modify behavior without rewriting entire programs
3. **Portability**: Same constraints run on different controller platforms
4. **Verification**: Can mathematically prove constraints are never violated
5. **Separation of concerns**: Regulations, topology, and behavior are independent
6. **Easier testing**: Clear validation rules for program correctness

## See Also

- [Configuring the Validator]({% link pages/configuring.md %})
- [Architecture]({% link pages/architecture.md %})
- [Group-Based Programming Specification](https://github.com/rsmp-nordic/tlc_programming/blob/main/group_based.md)
