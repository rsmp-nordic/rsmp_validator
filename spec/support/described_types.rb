# frozen_string_literal: true

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

    Alarm = Class.new(Base)
    Clock = Class.new(Base)
    DetectorLogics = Class.new(Base)
    EmergencyRoutes = Class.new(Base)
    InvalidCommand = Class.new(Base)
    InvalidStatus = Class.new(Base)
    Io = Class.new(Base)
    Modes = Class.new(Base)
    SignalGroups = Class.new(Base)
    SignalPlans = Class.new(Base)
    SignalPriority = Class.new(Base)
    Subscribe = Class.new(Base)
    System = Class.new(Base)
    TrafficData = Class.new(Base)
    TrafficSituations = Class.new(Base)
  end
end
