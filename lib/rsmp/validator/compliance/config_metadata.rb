# frozen_string_literal: true

require 'yaml'

module RSMP
  module Validator
    module Compliance
      # Reads stable compliance target metadata from a validator YAML config file.
      class ConfigMetadata
        def initialize(path)
          @path = path
        end

        def target
          return {} unless @path && File.exist?(@path)

          metadata = YAML.safe_load_file(@path, aliases: true)['compliance']
          metadata.is_a?(Hash) ? stringify(metadata) : {}
        rescue Psych::Exception
          {}
        end

        private

        def stringify(hash)
          hash.transform_keys(&:to_s).transform_values { |value| value.is_a?(Hash) ? stringify(value) : value }
        end
      end
    end
  end
end
