require 'yaml'

module Validator
  module Configuration
    def load_tester_config
      config_path = get_config_path
      raw_config = load_yaml_config!(
        config_path,
        using_message: "Using #{mode} config: #{config_path}",
        missing_message: "#{mode.capitalize} config file #{config_path} is missing"
      )

      options = build_tester_options(raw_config, config_path)
      apply_loaded_config(options)

      validate_mode_config!(config_path)
      validate_components_config!
      validate_timeouts_config!
      normalize_core_version!
      load_secrets config_path
    end

    def load_auto_node_config
      path = auto_node_config_path
      return unless path

      log "Will run auto #{mode} with config: #{path}"
      raw_config = load_yaml_config!(
        path,
        using_message: '',
        missing_message: "Auto #{mode} config file #{path} is missing"
      )
      options_class = auto_node_options_class_for(raw_config)
      options = build_options_from_raw(raw_config, path, options_class)
      self.auto_node_config = options.to_h
      self.auto_node_log_settings = options.log_settings
    end

    def get_config_path(local: false)
      mode_name = mode.to_s
      config_path = get_config_path_from_env(mode_name) || get_config_path_from_validator_yaml(mode_name)
      abort_with_error "#{mode_name.capitalize} config path not set" unless config_path && config_path != ''

      config_path = File.expand_path(config_path) if local
      config_path
    end

    def auto_node_config_path
      env_key = mode == :site ? 'AUTO_SITE_CONFIG' : 'AUTO_SUPERVISOR_CONFIG'
      env_path = ENV.fetch(env_key, nil)
      return env_path if env_path && !env_path.empty?

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

    def build_tester_options(raw_config, config_path)
      options_class = tester_options_class_for(raw_config)
      build_options_from_raw(raw_config, config_path, options_class)
    end

    def apply_loaded_config(options)
      self.config = options.to_h
      self.config_log_settings = options.log_settings
    end

    def load_yaml_config!(path, using_message:, missing_message:)
      ensure_config_exists!(path, missing_message)
      log_using_message(using_message)

      raw = YAML.load_file(path)
      validate_config_hash!(raw, path)
      raw || {}
    rescue Psych::SyntaxError => e
      raise RSMP::ConfigurationError, "Cannot read config file #{path}: #{e}"
    end

    def ensure_config_exists!(path, missing_message)
      abort_with_error missing_message unless File.exist?(path)
    end

    def log_using_message(using_message)
      return if using_message.nil? || using_message.empty?

      log using_message
    end

    def validate_config_hash!(raw, path)
      return if raw.is_a?(Hash) || raw.nil?

      raise RSMP::ConfigurationError, "Config #{path} must be a hash"
    end

    def build_options_from_raw(raw, path, option_class)
      log_settings = raw.is_a?(Hash) ? raw['log'] : nil
      options_hash = raw.is_a?(Hash) ? raw.dup : {}
      options_hash.delete('log') if options_hash.is_a?(Hash)

      option_class.new(options_hash, source: path, log_settings: log_settings)
    rescue RSMP::ConfigurationError => e
      abort_with_error e.message
    end

    def tester_options_class_for(_raw)
      case mode
      when :site
        Validator::SiteTest::Options
      when :supervisor
        Validator::SupervisorTest::Options
      else
        abort_with_error "Unknown test mode: #{mode}"
      end
    end

    def auto_node_options_class_for(raw)
      case mode
      when :site
        site_options_class_for(raw)
      when :supervisor
        RSMP::Supervisor::Options
      else
        abort_with_error "Unknown test mode: #{mode}"
      end
    end

    def site_options_class_for(raw)
      return RSMP::Site::Options unless raw.is_a?(Hash)

      type = raw['type']
      type == 'tlc' ? RSMP::TLC::TrafficControllerSite::Options : RSMP::Site::Options
    end

    def get_config_path_from_env(mode_name)
      key = "#{mode_name.upcase}_CONFIG"
      ENV.fetch(key, nil)
    end

    def get_config_path_from_validator_yaml(mode_name)
      ref_path = 'config/validator.yaml'
      return nil unless File.exist? ref_path

      config_ref = YAML.load_file ref_path
      config_ref[mode_name].to_s.strip
    end

    def validate_mode_config!(config_path)
      case mode
      when :supervisor
        validate_supervisor_mode_config!(config_path)
      when :site
        validate_site_mode_config!(config_path)
      end
    end

    def validate_supervisor_mode_config!(config_path)
      return if config['local_site'] && !top_level_site_settings?

      if top_level_site_settings?
        abort_with_error <<~HEREDOC
          Error:
          The config file at #{config_path} contains site settings at the top level.
          For supervisor testing, put site settings under 'local_site'.
          Check that you're using the right config file, or fix the config.
        HEREDOC
      else
        abort_with_error <<~HEREDOC
          Error:
          The config file at #{config_path} is missing 'local_site'.
          For supervisor testing, the config must describe the local site used during testing.
          Check that you're using the right config file, or fix the config.
        HEREDOC
      end
    end

    def validate_site_mode_config!(config_path)
      return if config['local_supervisor'] && !top_level_supervisor_settings?

      if top_level_supervisor_settings?
        abort_with_error <<~HEREDOC
          Error:
          The config file at #{config_path} contains supervisor settings at the top level.
          For site testing, put supervisor settings under 'local_supervisor'.
          Check that you're using the right config file, or fix the config.
        HEREDOC
      else
        abort_with_error <<~HEREDOC
          Error:
          The config file at #{config_path} is missing 'local_supervisor'.
          For site testing, the config must describe the local supervisor used during testing.
          Check that you're using the right config file, or fix the config.
        HEREDOC
      end
    end

    def top_level_site_settings?
      config['port'] || config['supervisors'] || config['site_id'] || config['type'] || config['intervals']
    end

    def top_level_supervisor_settings?
      config['supervisors'] || config['port'] || config['guest']
    end

    def validate_components_config!
      abort_with_error "Error: config 'components' settings is missing or empty" if config['components'] == {}

      main_component = config.dig('components', 'main')&.keys&.first
      abort_with_error "Error: config 'main' component settings is missing or empty" unless main_component

      config['main_component'] = main_component
    end

    def validate_timeouts_config!
      timeouts = config['timeouts']
      abort_with_error "Error: config 'timeouts' settings is missing or empty" if timeouts.nil? || timeouts == {}
    end

    def normalize_core_version!
      core_version = ENV['CORE_VERSION'] || config['core_version'] || RSMP::Schema.latest_core_version
      core_version = RSMP::Schema.latest_core_version if core_version == 'latest'

      known_versions = RSMP::Schema.core_versions
      normalized_core_version = normalized_core_version(core_version, known_versions)
      return config['core_version'] = normalized_core_version.to_s if normalized_core_version

      abort_with_error "Unknown core version #{core_version}, must be one of [#{known_versions.join(', ')}]."
    end

    def normalized_core_version(core_version, known_versions)
      known_versions.map { |v| Gem::Version.new(v) }.sort.reverse.detect do |v|
        Gem::Requirement.new(core_version).satisfied_by?(v)
      end
    end

    def load_secrets(config_path)
      load_secrets_file(config_path) unless config['secrets']
      normalize_security_codes!
      warn_missing_security_codes
    end

    def normalize_security_codes!
      codes = config.dig('secrets', 'security_codes')
      return unless codes.is_a?(Hash)

      normalized = codes.each_with_object({}) do |(key, value), memo|
        int_key = key.is_a?(String) && key.match?(/^\d+$/) ? key.to_i : key
        memo[int_key] = value
      end

      config['secrets']['security_codes'] = normalized
    end

    def load_secrets_file(config_path)
      basename = File.basename(config_path, '.yaml')
      folder = File.dirname(config_path)
      secrets_path = File.join(folder, "#{basename}_secrets.yaml")
      return unless File.exist?(secrets_path)

      config['secrets'] = YAML.load_file(secrets_path)
    end

    def warn_missing_security_codes
      return warn_no_security_code unless config.dig('secrets', 'security_codes')

      warn_security_code_not_configured(1) unless config.dig('secrets', 'security_codes', 1)
      warn_security_code_not_configured(2) unless config.dig('secrets', 'security_codes', 2)
    end

    def warn_no_security_code
      log 'Warning: No security code configured'.colorize(:yellow)
    end

    def warn_security_code_not_configured(index)
      log "Warning: Security code #{index} is not configured".colorize(:yellow)
    end
  end
end
