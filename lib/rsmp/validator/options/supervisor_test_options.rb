require 'rsmp'

module RSMP
  module Validator
    module SupervisorTest
      # Configuration options for supervisor testing.
      class Options < RSMP::Options
        def schema_file
          'supervisor_test.json'
        end

        def schema_path
          File.expand_path("../../../schemas/#{schema_file}", __dir__)
        end

        private

        def apply_defaults(options)
          return options unless options.is_a?(Hash)

          local_site = options['local_site']
          return options unless local_site.is_a?(Hash)

          merge_site_defaults(options, local_site)
          site_options_class = site_options_class_for(local_site)
          local_site = normalize_local_site_for_rsmp(local_site)
          local_site = site_options_class.new(local_site).to_h

          options.merge('local_site' => local_site)
        end

        def merge_site_defaults(options, local_site)
          rsmp_site_default_keys.each do |key|
            value = options[key]
            next if value.nil? || local_site.key?(key)

            value = rsmp_timeouts(value) if key == 'timeouts'
            next if value == {}

            local_site[key] = value
          end
        end

        def rsmp_site_default_keys
          %w[
            sxls
            core_version
            intervals
            timeouts
            components
            skip_validation
          ]
        end

        def site_options_class_for(local_site)
          local_site['type'] == 'tlc' ? RSMP::TLC::TrafficControllerSite::Options : RSMP::Site::Options
        end

        def rsmp_timeouts(value)
          return value unless value.is_a?(Hash)

          value.slice(*rsmp_timeout_keys)
        end

        def rsmp_timeout_keys
          %w[
            connect
            ready
            watchdog
            acknowledgement
            command
            command_timeout
            status_response
          ]
        end

        def normalize_local_site_for_rsmp(local_site)
          normalized = local_site.dup
          if normalized['security_codes'].nil? && normalized.dig('secrets', 'security_codes').is_a?(Hash)
            normalized['security_codes'] = normalized['secrets']['security_codes']
          end
          normalized.delete('secrets')
          normalized
        end
      end
    end
  end
end
