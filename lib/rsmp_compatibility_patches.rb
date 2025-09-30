# Compatibility patches for the updated RSMP gem
# This file contains monkey patches to fix compatibility issues
# between the validator and the updated RSMP gem

# Load the RSMP gem first
require 'rsmp'

# Now monkey patch the TrafficControllerSite class
module RSMP
  module TLC
    class TrafficControllerSite
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