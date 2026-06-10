# Main module for RSMP Validator functionality.
module Validator
  # Helpers for filtering tests by RSMP core and SXL version.
  module VersionFilter
    # Check if the configured SXL version satisfies the given requirement.
    # @param requirement [String] Gem::Requirement-compatible string, e.g. ">= 1.0.7"
    def self.sxl_matches?(requirement, name: nil)
      sxl = configured_sxl(name)
      version_satisfies?(requirement, sxl && sxl['version'])
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

    def self.configured_sxl(name = nil)
      sxls = Validator.config['sxls'] || []
      return sxls.first unless name

      sxls.find { |sxl| sxl['name'] == name.to_s }
    end
  end

  # Convenience module methods delegating to VersionFilter
  def self.sxl_matches?(requirement, name: nil)
    VersionFilter.sxl_matches?(requirement, name: name)
  end

  def self.core_matches?(requirement)
    VersionFilter.core_matches?(requirement)
  end
end
