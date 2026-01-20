module Validator
  # Class used as a stream by the RSMP::Logger
  #
  # When RSMP::Logger writes to it, the data
  # is passed to an RSpec reporter, which
  # will in turn distribute it to the active
  # formatters.
  #
  # Formatters can write to separate file, or to the console.

  class ReportStream
    def initialize(rspec_reporter)
      @reporter = rspec_reporter
    end

    def puts(str)
      @reporter.publish :log, message: str
    end

    def flush; end
  end
end
