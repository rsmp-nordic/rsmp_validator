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

      # Patch the build_component method to handle ntsOId/ntsoid naming inconsistency
      def build_component(id:, type:, settings: {})
        case type
        when 'main'
          TrafficController.new node: self,
                                id: id,
                                ntsoid: settings['ntsOId'] || settings['ntsoid'],
                                xnid: settings['xNId'] || settings['xnid'],
                                startup_sequence: @startup_sequence,
                                signal_plans: @signal_plans,
                                live_output: @site_settings['live_output'],
                                inputs: @site_settings['inputs']
        when 'signal_group'
          group = SignalGroup.new node: self, id: id
          main.add_signal_group group
          group
        when 'detector_logic'
          logic = DetectorLogic.new node: self, id: id
          main.add_detector_logic logic
          logic
        end
      end
    end
  end

  # Ensure version_meets_requirement? is available as a class method on Proxy
  # This may be redundant but ensures compatibility
  class Proxy
    def self.version_meets_requirement?(version, requirement)
      Gem::Requirement.new(requirement).satisfied_by?(Gem::Version.new(version))
    end
  end
end