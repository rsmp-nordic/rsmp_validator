---
layout: page
title: Other RSMP Tools
permalink: /other_tools/
nav_order: 6
parent: Resources
---

# RSMP Testing Tools Overview
RSMP Nordic maintains a set of open-source RSMP testing tools. The tools can be used to validate the correctness and completeness of RSMP implementations, or as an assistance during development.

The RSMP testing tools are written in Ruby and includes libraries that can be used as building blocks for building you own custom RSMP tools.

## RSMP Simulator
An easy-to-use Windows app that can connect to RSMP equipment or systems. You can manually change statuses, send commands, raise alarms, etc. and see what messages are being exchanged.

## RSMP Validator
The validator can perform automated testing of RSMP equipment or systems. It's based on RSpec and written in the Ruby language.

It include a set of tests that validate various aspects of an RSMP implementation. You can run all tests or a selection of tests, and get a report on any errors found.

## RSMP Libraries
The RSMP Validator relies on RSMP libraries for handling RSMP communication, validation RSMP message, etc. These RSMP libraries can also be used independently in case you want to build your own RSMP tools. They are written in Ruby.

### rsmp (Gem)
A Ruby gem (library) which implements the RSMP protocol. It makes it easy to programmatically and concurrently run RSMP sites or supervisors, send and wait for messages, etc.

The gem also include a simple Traffic Light Controller emulator, which implements enough functionality to pass all tests in the RSMP Validator.

The gem include command-line tools for quickly running rsmp supervisors or sites.

### rsmp_schemer (Gem)
A Ruby gem (library) that makes it easy to validate RSMP messages against specific version of RSMP core and SXL JSON Schemas.

The gem `json_schemer` is used to perform actual JSON Schema validaton.

### rsmp_schema (JSON Schema)
JSON Schemas documenting the format of all RSMP messages in a machine-readable format. The schema is useful for automatically validating RSMP messsages.

There's a schema covering the Core specification, and a schema for Traffic Light Controllers. For each schema, we maintain branches for each released version.

Validating RSMP messages against the JSON Schema requires the use of a JSON Schema validation library. These exist for all major programming languages. For Ruby, you can use the rsmp_schemer gem to easily handle validation against a specific schema.
