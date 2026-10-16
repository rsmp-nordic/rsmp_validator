module RSMP
  module Validator
    # Sus fixture module that runs each test inside the shared Async reactor.
    # Include this in the sus base class to ensure all tests run within the reactor context.
    module AsyncContext
      def around(&block)
        task = RSMP::Validator.reactor.run do |_task|
          catch(:rsmp_validator_test_failure, &block)
        ensure
          RSMP::Validator.reactor.interrupt
        end
        task.wait
      end
    end
  end
end
