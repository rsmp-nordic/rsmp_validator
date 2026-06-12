module RSMP
  module Validator
    # Logging helpers for use in tests and validator infrastructure.
    module Log
      # Log the start of an action
      def log(action, **options)
        RSMP::Validator.log(action, **options)
      end
    end
  end
end
