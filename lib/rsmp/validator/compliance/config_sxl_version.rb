# frozen_string_literal: true

require 'yaml'

module RSMP
  module Validator
    module Compliance
      # Reads the primary SXL version from a validator YAML config file.
      class ConfigSxlVersion
        def initialize(path)
          @path = path
        end

        def version
          return nil unless @path && File.exist?(@path)

          extract_version(YAML.safe_load_file(@path, aliases: true)['sxls'])
        rescue Psych::Exception
          nil
        end

        private

        def extract_version(sxls)
          return sxls.values.first.to_s if sxls.is_a?(Hash)

          extract_array_version(sxls) if sxls.is_a?(Array)
        end

        def extract_array_version(sxls)
          first = sxls.first
          first.is_a?(Hash) ? first['version'].to_s : first.to_s
        end
      end
    end
  end
end
