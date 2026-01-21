require 'rsmp'

module Validator
  module SupervisorTest
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

        %w[
          sxl
          sxl_version
          core_version
          rsmp_versions
          intervals
          timeouts
          components
          skip_validation
        ].each do |key|
          value = options[key]
          next if value.nil? || local_site.key?(key)

          local_site[key] = value
        end

        site_options_class = if local_site['type'] == 'tlc'
                               RSMP::TLC::TrafficControllerSite::Options
                             else
                               RSMP::Site::Options
                             end
        local_site = site_options_class.new(local_site).to_h

        options.merge('local_site' => local_site)
      end
    end
  end
end
