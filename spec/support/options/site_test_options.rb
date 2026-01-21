require 'rsmp'

module Validator
  module SiteTest
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

        local_supervisor['guest'] = merge_guest_defaults(options, local_supervisor['guest'])
        local_supervisor = RSMP::Supervisor::Options.new(local_supervisor).to_h
        options.merge('local_supervisor' => local_supervisor)
      end

      def merge_guest_defaults(options, guest)
        merged_guest = guest.is_a?(Hash) ? guest.dup : {}

        guest_defaults.each do |key|
          value = options[key]
          next if value.nil? || merged_guest.key?(key)

          merged_guest[key] = value
        end

        merged_guest
      end

      def guest_defaults
        %w[
          sxl
          sxl_version
          core_version
          rsmp_versions
          intervals
          timeouts
          components
          skip_validation
        ]
      end
    end
  end
end
