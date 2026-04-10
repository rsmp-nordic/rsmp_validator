module Validator
  module Configuration
    # Private helpers for loading and normalizing secrets configuration.
    module Secrets
      private

      def load_secrets(config_path)
        load_secrets_file(config_path) unless config['secrets']
        normalize_security_codes!
        warn_missing_security_codes
      end

      def load_secrets_file(config_path)
        basename = File.basename(config_path, '.yaml')
        folder = File.dirname(config_path)
        secrets_path = File.join(folder, "#{basename}_secrets.yaml")
        return unless File.exist?(secrets_path)

        config['secrets'] = YAML.load_file(secrets_path)
      rescue Psych::SyntaxError => e
        abort_with_error "Cannot read secrets file #{secrets_path}: #{e}"
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
end
