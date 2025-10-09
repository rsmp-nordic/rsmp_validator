# Group-Based Programming Implementation

This document summarizes the implementation of group-based programming support in the RSMP Validator.

## Overview

Group-based programming is a modern approach to traffic light control based on constraint programming rather than traditional phase-based programming. This implementation adds complete support for defining, validating, and testing group-based traffic control programs.

## Implementation Details

### Core Classes

#### 1. `Validator::GroupBasedProgram` (lib/validator/group_based_program.rb)

Represents a complete group-based traffic control program with:
- Program metadata (id, version, description)
- Timing constraints (min/max green times per signal group)
- Detector logics (how detectors create demand for signal groups)
- Extension rules (gap-out logic, maximum extensions)
- Optimization objectives (minimize delay, stops, etc.)

**Key Methods:**
- `timing_for(signal_group)` - Get timing configuration for a signal group
- `detector_logics_for(signal_group)` - Get detector logics for a signal group
- `extension_rule_for(signal_group)` - Get extension rule for a signal group
- `validate()` - Validate program structure
- `to_h()` - Convert to hash representation

#### 2. `Validator::ConstraintValidator` (lib/validator/constraint_validator.rb)

Validates programs against regional and intersection constraints:
- Signal group validation (all references must exist)
- Timing constraint validation (against regional regulations)
- Detector reference validation (all detectors must exist)
- Conflict constraint validation (build conflict matrix)
- Intergreen time validation (positive clearance times)

**Key Methods:**
- `validate()` - Validate all constraints
- `conflicts?(sg1, sg2)` - Check if two signal groups conflict
- `min_intergreen_time(from_sg, to_sg)` - Get minimum clearance time

### Configuration Layers

The implementation supports three configuration layers as defined in the specification:

1. **Regional Configuration** - Regulatory constraints (yellow times, min/max green times)
2. **Intersection Configuration** - Physical topology (signal groups, conflicts, intergreens, detectors)
3. **Program** - Operational behavior (timing, detector logics, extensions, objectives)

### Helper Methods

Added to `spec/support/programming_helpers.rb`:
- `load_group_based_program(program_id)` - Load program from configuration
- `validate_group_based_program(program)` - Validate with constraints
- `get_program_timing(program, signal_group)` - Get timing configuration
- `has_detector_logic?(program, signal_group)` - Check if detector logic exists

## Testing

### Unit Tests (26 tests total)

**GroupBasedProgram Tests** (spec/lib/group_based_program_spec.rb) - 12 tests:
- Program initialization and configuration
- Timing queries
- Detector logic queries
- Extension rule queries
- Validation (missing id, version, invalid timing)
- Serialization to hash

**ConstraintValidator Tests** (spec/lib/constraint_validator_spec.rb) - 14 tests:
- Complete validation
- Signal group validation
- Timing constraint validation
- Detector reference validation
- Conflict identification
- Intergreen time queries and validation

### Integration Tests (6 tests)

**Group-Based Programming Tests** (spec/site/tlc/group_based_program_spec.rb):
- Program loading from configuration
- Constraint satisfaction validation
- Timing accessibility
- Detector logic configuration
- Extension rule references
- Program serialization

All tests pass successfully.

## Configuration Example

```yaml
# Regional regulatory constraints
regional_config:
  regulations:
    minimum_green_times:
      vehicle: 5
      pedestrian: 6
    maximum_green_times:
      default: 120

# Intersection topology
intersection_config:
  signal_groups:
    sg1: { type: "vehicle" }
    sg2: { type: "vehicle" }
  conflicts:
    - groups: [sg1, sg2]
  intergreens:
    - from: sg1
      to: sg2
      min_time: 4
  detectors:
    d1: { type: "loop" }

# Program definition
group_based_programs:
  actuated_v1:
    id: "program_1"
    version: "1.0"
    timing:
      sg1: { min_green: 10, max_green: 60 }
    detector_logics:
      - detectors: [d1]
        creates_demand_for: sg1
        priority: 5
    extension_rules:
      - signal_group: sg1
        type: "gap_out"
        gap_time: 3
```

## Files Added/Modified

**New Files:**
- `lib/validator/group_based_program.rb` - GroupBasedProgram class
- `lib/validator/constraint_validator.rb` - ConstraintValidator class
- `spec/lib/group_based_program_spec.rb` - Unit tests for GroupBasedProgram
- `spec/lib/constraint_validator_spec.rb` - Unit tests for ConstraintValidator
- `spec/site/tlc/group_based_program_spec.rb` - Integration tests
- `config/group_based_program_example.yaml` - Example configuration
- `examples/group_based_program_example.rb` - Runnable example
- `docs/pages/group_based_programming.md` - Comprehensive documentation

**Modified Files:**
- `spec/support/programming_helpers.rb` - Added helper methods
- `docs/pages/configuring.md` - Added group-based programming section

**Total:** 1418 lines added across 10 files

## Usage Example

```ruby
# Load program
program = load_group_based_program('actuated_v1')

# Validate constraints
errors = validate_group_based_program(program)
puts "Valid!" if errors.empty?

# Query timing
timing = get_program_timing(program, 'sg1')
# => { 'min_green' => 10, 'max_green' => 60 }

# Check detector logic
has_detector_logic?(program, 'sg1')  # => true
```

## Running Tests

```bash
# Unit tests (without validator infrastructure)
bundle exec rspec spec/lib/ --options /dev/null

# Integration tests (requires configuration)
SITE_CONFIG=config/group_based_program_example.yaml \
  bundle exec rspec spec/site/tlc/group_based_program_spec.rb

# Example script
ruby examples/group_based_program_example.rb
```

## Documentation

Complete documentation is available at:
- `docs/pages/group_based_programming.md` - Full guide with examples
- `docs/pages/configuring.md` - Configuration section updated
- Comments in source code (YARD-compatible)

## Benefits

1. **Safety First** - Hard constraints ensure safety rules are never violated
2. **Flexibility** - Easy to modify behavior without rewriting entire programs
3. **Validation** - Comprehensive constraint checking catches errors early
4. **Testability** - Clear validation rules make testing straightforward
5. **Documentation** - Well-documented with examples and guides
6. **Standards Compliant** - Follows group-based programming specification

## Future Enhancements

Possible future improvements:
- RSMP message integration (S0098 for reading program configuration)
- Real-time constraint monitoring during execution
- Program comparison and diff tools
- Visual constraint graph rendering
- Performance profiling and optimization analysis

## References

- [Group-Based Programming Specification](https://github.com/rsmp-nordic/tlc_programming/blob/main/group_based.md)
- [RSMP Validator Documentation](https://rsmp-nordic.github.io/rsmp_validator/)
