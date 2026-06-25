require 'yaml'
require_relative 'configuration/loader'
require_relative 'configuration/validation'
require_relative 'configuration/secrets'

module RSMP
  module Validator
    # Handles loading and validating validator configuration files.
    module Configuration
      include Loader
      include Validation
      include Secrets

      def load_tester_config
        config_path = get_config_path
        raw_config = load_yaml_config!(
          config_path,
          using_message: "Using #{mode} config: #{config_path}",
          missing_message: "#{mode.capitalize} config file #{config_path} is missing"
        )

        apply_cli_overrides!(raw_config)
        options = build_tester_options(raw_config, config_path)
        apply_loaded_config(options)
        validate_and_finalize_config!(config_path)
      end

      def apply_cli_overrides!(raw_config)
        raw_config['core_version'] = core_version_override if core_version_override
        raw_config['sxls'] = parse_sxls(sxls_override) if sxls_override
      end

      def validate_and_finalize_config!(config_path)
        validate_mode_config!(config_path)
        validate_components_config!
        validate_timeouts_config!
        normalize_core_version!
        normalize_sxls!
        load_secrets config_path
      end

      def load_auto_node_config
        path = auto_node_config_path
        return unless path

        @log_stream.puts "Will run auto #{mode} with config: #{path}"
        raw_config = load_yaml_config!(
          path,
          using_message: '',
          missing_message: "Auto #{mode} config file #{path} is missing"
        )
        raw_config['sxls'] = parse_sxls(sxls_override) if sxls_override
        options_class = auto_node_options_class_for(raw_config)
        options = build_options_from_raw(raw_config, path, options_class)
        self.auto_node_config = options.to_h
        self.auto_node_log_settings = options.log_settings
      end

      def get_config_path(local: false)
        mode_name = mode.to_s
        config_path = config_path_option(mode_name) || get_config_path_from_validator_yaml(mode_name)
        abort_with_error "#{mode_name.capitalize} config path not set" unless config_path && config_path != ''

        config_path = File.expand_path(config_path) if local
        self.config_path = config_path
        config_path
      end

      def auto_node_config_path
        option_path = auto_config_path_option(mode.to_s)
        return option_path if option_path && !option_path.empty?

        ref_path = 'config/validator.yaml'
        return nil unless File.exist? ref_path

        config_ref = YAML.load_file ref_path
        key = mode == :site ? 'auto_site' : 'auto_supervisor'
        path = config_ref[key].to_s.strip
        path.empty? ? nil : path
      end

      def get_config(*path, **options)
        value = config.dig(*path)
        return value if value

        path_name = path.inspect
        default = options[:default]
        assume = options[:assume]
        if default
          warning "Config #{path_name} not found, using default: #{default}"
          default
        elsif assume
          assume
        else
          raise "Config #{path_name} is missing"
        end
      end

      private

      def config_path_option(mode_name)
        case mode_name
        when 'site' then site_config_path
        when 'supervisor' then supervisor_config_path
        end
      end

      def auto_config_path_option(mode_name)
        case mode_name
        when 'site' then auto_site_config_path
        when 'supervisor' then auto_supervisor_config_path
        end
      end

      def get_config_path_from_validator_yaml(mode_name)
        ref_path = 'config/validator.yaml'
        return nil unless File.exist? ref_path

        config_ref = YAML.load_file ref_path
        config_ref[mode_name].to_s.strip
      end

      def warning(message)
        log "Warning: #{message}", level: :warning
      end

      def parse_sxls(value)
        value.split(',').each_with_object({}) do |item, memo|
          parts = item.split(':')
          abort_with_error "Invalid --sxls item #{item.inspect}, expected name:version" unless parts.length == 2

          name, version = parts
          memo[name] = version
        end
      end
    end
  end
end
