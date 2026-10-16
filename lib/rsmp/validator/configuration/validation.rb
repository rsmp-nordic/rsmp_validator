module RSMP
  module Validator
    module Configuration
      # Private helpers for validating configuration values.
      module Validation
        private

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
          %w[site_id supervisors type].any? { |key| config.key?(key) }
        end

        def top_level_supervisor_settings?
          %w[port ips max_sites].any? { |key| config.key?(key) }
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
      end
    end
  end
end
