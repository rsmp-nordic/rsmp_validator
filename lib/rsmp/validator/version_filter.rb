# Main module for RSMP Validator functionality.
module Validator
  # Helpers for filtering tests by RSMP core and SXL version.
  module VersionFilter
    # Check if the configured SXL version satisfies the given requirement.
    # @param requirement [String] Gem::Requirement-compatible string, e.g. ">= 1.0.7"
    def self.sxl_matches?(requirement)
      version_satisfies?(requirement, Validator.config['sxl_version'])
    end

    # Check if the configured core version satisfies the given requirement.
    # @param requirement [String] Gem::Requirement-compatible string, e.g. ">= 3.2"
    def self.core_matches?(requirement)
      version_satisfies?(requirement, Validator.config['core_version'])
    end

    # Helper that does the version comparison.
    def self.version_satisfies?(requirement, version_str)
      return false unless version_str

      version = Gem::Version.new(version_str)
      Gem::Requirement.new(requirement).satisfied_by?(version)
    end
  end

  # Convenience module methods delegating to VersionFilter
  def self.sxl_matches?(requirement)
    VersionFilter.sxl_matches?(requirement)
  end

  def self.core_matches?(requirement)
    VersionFilter.core_matches?(requirement)
  end
end
