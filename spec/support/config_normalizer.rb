module Validator
  module ConfigNormalizer
    def self.normalize_site_settings(settings)
      normalized = deep_dup(settings)

      if normalized['security_codes'].nil? && normalized.dig('secrets', 'security_codes').is_a?(Hash)
        normalized['security_codes'] = deep_dup(normalized['secrets']['security_codes'])
      end

      normalize_security_codes!(normalized)
      normalize_input_programming!(normalized)

      normalized
    end

    def self.normalize_security_codes!(settings)
      codes = settings['security_codes']
      return unless codes.is_a?(Hash)

      settings['security_codes'] = codes.each_with_object({}) do |(key, value), memo|
        int_key = key.is_a?(String) && key.match?(/^\d+$/) ? key.to_i : key
        memo[int_key] = value
      end
    end

    def self.normalize_input_programming!(settings)
      programming = settings.dig('inputs', 'programming')
      return unless programming.is_a?(Hash)

      normalized = normalize_programming_keys(programming)
      return unless normalized.keys.all?(Integer)

      settings['inputs'] ||= {}
      settings['inputs']['programming'] = build_programming_array(normalized)
    end

    def self.normalize_programming_keys(programming)
      programming.each_with_object({}) do |(key, value), memo|
        int_key = key.is_a?(String) && key.match?(/^\d+$/) ? key.to_i : key
        memo[int_key] = value
      end
    end

    def self.build_programming_array(normalized)
      max_key = normalized.keys.max
      program_array = Array.new(max_key + 1)
      normalized.each do |index, value|
        program_array[index] = value
      end
      program_array
    end

    def self.deep_dup(value)
      case value
      when Hash
        value.transform_values { |v| deep_dup(v) }
      when Array
        value.map { |item| deep_dup(item) }
      else
        value
      end
    end
  end
end
