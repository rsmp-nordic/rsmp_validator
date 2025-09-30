# Compatibility patches for the updated RSMP gem
# This file contains monkey patches to fix compatibility issues
# between the validator and the updated RSMP gem

# Load the RSMP gem first
require 'rsmp'

# Now monkey patch the TrafficControllerSite class
module RSMP
  module TLC
    class TrafficControllerSite
      # Patch the build_plans method to use the correct keyword argument
      def build_plans(signal_plans)
        @signal_plans = {}
        return unless signal_plans

        signal_plans.each_pair do |id, settings|
          states = nil
          cycle_time = settings['cycle_time']
          states = settings['states'] if settings
          dynamic_bands = settings['dynamic_bands'] if settings

          @signal_plans[id.to_i] =
            SignalPlan.new(number: id.to_i, cycle_time: cycle_time, states: states, dynamic_bands: dynamic_bands)
        end
      end
    end
  end
end