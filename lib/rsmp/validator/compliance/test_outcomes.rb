# frozen_string_literal: true

require 'sus'

module RSMP
  module Validator
    module Compliance
      # One outcome per executed Sus example, keyed by its file and nested descriptions.
      class TestOutcomes
        def initialize(assertions)
          @assertions = assertions
        end

        def to_h
          examples = @assertions.passed + @assertions.failed + @assertions.errored
          examples.each_with_object({}) do |result, outcomes|
            next unless result.is_a?(Sus::Assertions) && result.target.is_a?(Sus::It)

            outcomes[test_id(result.target)] = outcome(result)
          end
        end

        private

        def outcome(result)
          return 'errored' if result.errored?
          return 'failed' if result.failed?
          # Sus also includes skipped examples in its passed collection.
          return 'skipped' if result.skipped.any?

          'passed'
        end

        def test_id(context)
          unless context.identity.parent
            path = File.expand_path(context.identity.path).delete_prefix("#{Dir.pwd}/")
            return escape_part(path)
          end

          "#{test_id(context.superclass)}##{context_name(context)}"
        end

        def context_name(context)
          siblings = context.superclass.children.values.take_while { |child| child != context }
          occurrence = siblings.count { |child| child.description == context.description } + 1
          name = escape_part(context.description.to_s)
          occurrence == 1 ? name : "#{name}@#{occurrence}"
        end

        def escape_part(value)
          value.gsub(/[%#@]/, '%' => '%25', '#' => '%23', '@' => '%40')
        end
      end
    end
  end
end
