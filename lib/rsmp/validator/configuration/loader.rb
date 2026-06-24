module RSMP
  module Validator
    module Configuration
      # Private helpers for loading YAML config files and building options objects.
      module Loader
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
          @log_stream.puts using_message if using_message && !using_message.empty?
          raw = YAML.load_file(path)
          validate_config_hash!(raw, path)
          raw || {}
        rescue Psych::SyntaxError => e
          raise RSMP::ConfigurationError, "Cannot read config file #{path}: #{e}"
        end

        def ensure_config_exists!(path, missing_message)
          abort_with_error missing_message unless File.exist?(path)
          abort_with_error "Config #{path} is not a file" unless File.file?(path)
          abort_with_error "Config #{path} must be a YAML file (.yml or .yaml)" unless yaml_file?(path)
        end

        def yaml_file?(path)
          %w[.yml .yaml].include?(File.extname(path).downcase)
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
            RSMP::Validator::SiteTest::Options
          when :supervisor
            RSMP::Validator::SupervisorTest::Options
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
      end
    end
  end
end
