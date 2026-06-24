module RSMP
  module Validator
    # Writes to two IOs simultaneously through a single object, so both RSMP
    # messages and Sus verbose output can share one file descriptor.
    class TeeIO
      def initialize(primary, secondary)
        @primary = primary
        @secondary = secondary
      end

      def write(*args)
        @primary.write(*args)
        @secondary.write(*args)
      end

      def puts(*args)
        @primary.puts(*args)
        @secondary.puts(*args)
      end

      def flush
        @primary.flush
        @secondary.flush
      end

      def isatty = @primary.isatty
      def tty? = @primary.tty?
    end
  end
end
