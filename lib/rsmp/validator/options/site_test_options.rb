require 'rsmp'

module RSMP
  module Validator
    module SiteTest
      # Configuration options for site testing.
      class Options < RSMP::Options
        def schema_file
          'site_test.json'
        end

        def schema_path
          File.expand_path("../../../schemas/#{schema_file}", __dir__)
        end

        private

        def apply_defaults(options)
          return options unless options.is_a?(Hash)

          local_supervisor = options['local_supervisor']
          return options unless local_supervisor.is_a?(Hash)

          local_supervisor['sites'] ||= {}
          local_supervisor['sites']['default'] =
            merge_default_defaults(options, local_supervisor.dig('sites', 'default'))
          local_supervisor = RSMP::Supervisor::Options.new(local_supervisor).to_h
          options.merge('local_supervisor' => local_supervisor)
        end

        def merge_default_defaults(options, default)
          merged_default = default.is_a?(Hash) ? default.dup : {}

          site_defaults.each do |key|
            value = options[key]
            next if value.nil? || merged_default.key?(key)

            value = rsmp_timeouts(value) if key == 'timeouts'
            next if value == {}

            merged_default[key] = value
          end

          merged_default
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

        def site_defaults
          %w[
            sxls
            core_version
            intervals
            timeouts
            components
            skip_validation
          ]
        end
      end
    end
  end
end
