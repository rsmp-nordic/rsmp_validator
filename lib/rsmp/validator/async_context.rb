module RSMP
  module Validator
    # Sus fixture module that runs each test inside the shared Async reactor.
    # Include this in the sus base class to ensure all tests run within the reactor context.
    module AsyncContext
      def around
        RSMP::Validator.reactor.run do |_task|
          yield
        ensure
          RSMP::Validator.reactor.interrupt
        end
      end
    end
  end
end
