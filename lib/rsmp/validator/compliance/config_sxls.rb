# frozen_string_literal: true

module RSMP
  module Validator
    module Compliance
      # Formats resolved validator SXL config for compliance reports.
      class ConfigSxls
        def initialize(config)
          @config = config
        end

        def to_h
          Array(@config && @config['sxls']).each_with_object({}) do |sxl, memo|
            next unless sxl.is_a?(Hash)

            name = sxl['name']
            version = sxl['version']
            memo[name.to_s] = version.to_s if name && version
          end
        end
      end
    end
  end
end
