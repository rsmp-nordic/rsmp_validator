require 'sus'

module RSMP
  module Validator
    module Helpers
      # Expectations for prerequisites that must pass before a test can continue.
      module Expectations
        # Keep Sus's reporting and chaining, then stop after recording a failure.
        class StoppingExpectation < Sus::Expect
          def to(predicate)
            result = nil
            super(lambda do |assertions, subject|
              result = assertions
              predicate.call(assertions, subject)
              if assertions.deferred?
                raise ArgumentError, 'expect_or_stop needs an immediate expectation; use expect for deferred assertions'
              end
            end)

            throw :rsmp_validator_test_failure unless result.passed?

            self
          end
        end

        # Stop the current conformance test on failure, unwinding ensure blocks.
        # Supports the same subjects, blocks, negation and chaining as expect,
        # but requires a predicate whose result is available immediately.
        def expect_or_stop(subject = nil, &block)
          StoppingExpectation.new(@__assertions__, block || subject, distinct: true)
        end
      end
    end
  end
end
