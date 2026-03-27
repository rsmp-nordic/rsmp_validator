# These constants exist purely to satisfy RuboCop RSpec cops that expect
# spec files to describe a class/module that matches the file path.
#
# The validator specs are integration-focused, so the described constants
# are not used for behavior.
module Site
  module Tlc
    Base = Class.new do
      def self.dummy?
        true
      end
    end

    class Alarm < Base
    end

    class Clock < Base
    end

    class DetectorLogics < Base
    end

    class EmergencyRoutes < Base
    end

    class InvalidCommand < Base
    end

    class InvalidStatus < Base
    end

    class Io < Base
    end

    class Modes < Base
    end

    class SignalGroups < Base
    end

    class SignalPlans < Base
    end

    class SignalPriority < Base
    end

    class Subscribe < Base
    end

    class System < Base
    end

    class TrafficData < Base
    end

    class TrafficSituations < Base
    end
  end
end
