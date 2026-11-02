require 'json'
require_relative 'version_normalization'
require_relative 'secrets'

module RSMP
  module Validator
    module Configuration
      # Validates the complete test configuration for each selected protocol version.
      class TestRequirements
        include VersionNormalization
        include Secrets

        SCHEMA_ROOT = File.expand_path('../../../../schemas/test_config', __dir__)

        attr_reader :config

        def initialize(options)
          @options = options
          @config = options.to_h
        end

        def validate!
          normalize_core_version!
          normalize_sxls!
          load_secrets_file(@options.source) if @options.source && !config['secrets']

          validate_versions!
          normalize_security_codes!
        end

        private

        def validate_versions!
          versions = JSON.parse(File.read(File.join(SCHEMA_ROOT, 'versions.json')))
          validate_version!(versions, 'core', config['core_version'])
          config['sxls'].each do |sxl|
            validate_version!(versions, sxl['name'], sxl['version'])
          end
        end

        def validate_version!(versions, name, version)
          # SXLs without a conformance suite have no additional test settings.
          return unless versions.key?(name)

          schema = versions.fetch(name)[version]
          abort_with_error "No test configuration schema for #{name} #{version}" unless schema

          path = File.join(SCHEMA_ROOT, schema)
          abort_with_error "Missing test configuration schema: #{path}" unless File.file?(path)

          # YAML security-code keys may be integers; JSON Schema uses string keys.
          @options.validate!(JSON.parse(JSON.generate(config)), path: path)
        rescue RSMP::ConfigurationError => e
          raise RSMP::ConfigurationError, "#{name} #{version}: #{e.message}"
        end

        def abort_with_error(message)
          raise RSMP::ConfigurationError, message
        end
      end
    end
  end
end
