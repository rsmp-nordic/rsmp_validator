require_relative 'auto_node'

module RSMP
  module Validator
    # Automatically starts a local RSMP site for testing.
    class AutoSite < RSMP::Validator::AutoNode
      protected

      def node_type
        'site'
      end

      def build_node
        klass = case config['type']
                when 'tlc'
                  RSMP::TLC::TrafficControllerSite
                else
                  RSMP::Site
                end

        site_settings = ConfigNormalizer.normalize_site_settings(config)

        klass.new(
          site_settings: site_settings,
          logger: create_logger
        )
      end
    end
  end
end
