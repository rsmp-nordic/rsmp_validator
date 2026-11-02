module RSMP
  module Validator
    # A required setting is missing from the test configuration.
    class MissingConfiguration < StandardError
      def initialize(path)
        super("Missing required test configuration: #{path.join('.')}")
      end
    end
  end
end
