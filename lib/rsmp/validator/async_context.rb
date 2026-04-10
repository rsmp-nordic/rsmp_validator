module Validator
  # Sus fixture module that runs each test inside the shared Async reactor.
  # Include this in the sus base class to ensure all tests run within the reactor context.
  module AsyncContext
    def around
      Validator.reactor.run do |_task|
        yield
      ensure
        Validator.reactor.interrupt
      end
    end
  end
end
