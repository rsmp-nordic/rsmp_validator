require 'yaml'
require_relative 'options/site_test_options'
require_relative 'options/supervisor_test_options'
require_relative 'configuration/sxls_override'
require_relative 'configuration/test_requirements'

module RSMP
  module Validator
    # Validates rsmp-validator config files and their embedded RSMP node config.
    class ConfigCheck
      Result = Struct.new(:path, :mode, :options, keyword_init: true)

      class << self
        include Configuration::SxlsOverride

        def check_file(path, mode: 'auto', core: nil, sxls: nil)
          raw = load_file(path)
          resolved_mode = resolve_mode(mode, raw)
          options = build_options(raw, mode: resolved_mode, path: path, core: core, sxls: sxls)

          Result.new(path: path, mode: resolved_mode, options: options)
        end

        def build_options(raw, mode:, path:, core: nil, sxls: nil)
          settings = config_settings(raw)
          settings['core_version'] = core if core
          settings['sxls'] = parse_sxls(sxls) if sxls
          options = options_class_for(mode.to_s).new(settings, source: path, log_settings: raw['log'])
          Configuration::TestRequirements.new(options).validate!
          options
        end

        private

        def abort_with_error(message)
          raise RSMP::ConfigurationError, message
        end

        def load_file(path)
          ensure_config_file!(path)

          raw = YAML.load_file(path)
          raise RSMP::ConfigurationError, "Config #{path} must be a hash" unless raw.is_a?(Hash) || raw.nil?

          raw || {}
        rescue Psych::SyntaxError => e
          raise RSMP::ConfigurationError, "Cannot read config file #{path}: #{e}"
        end

        def ensure_config_file!(path)
          raise RSMP::ConfigurationError, 'not found' unless File.exist?(path)
          raise RSMP::ConfigurationError, 'is not a file' unless File.file?(path)
          raise RSMP::ConfigurationError, 'must be a YAML file (.yml or .yaml)' unless yaml_file?(path)
        end

        def yaml_file?(path)
          %w[.yml .yaml].include?(File.extname(path).downcase)
        end

        def config_settings(raw)
          settings = raw.dup
          settings.delete('log')
          settings
        end

        def resolve_mode(mode, raw)
          mode = mode.to_s
          return mode if %w[site supervisor].include?(mode)
          raise RSMP::ConfigurationError, "Unknown config mode #{mode.inspect}" unless mode == 'auto'

          return 'site' if raw.key?('local_supervisor')
          return 'supervisor' if raw.key?('local_site')

          raise RSMP::ConfigurationError,
                'Cannot infer validator config mode; use --mode site or --mode supervisor'
        end

        def options_class_for(mode)
          case mode
          when 'site'
            RSMP::Validator::SiteTest::Options
          when 'supervisor'
            RSMP::Validator::SupervisorTest::Options
          else
            raise RSMP::ConfigurationError, "Unknown config mode #{mode.inspect}"
          end
        end
      end
    end
  end
end
