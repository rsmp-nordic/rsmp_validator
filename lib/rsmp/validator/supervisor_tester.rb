require 'rsmp'
require 'singleton'
require 'colorize'

module RSMP
  module Validator
    # Helper class for testing RSMP supervisors.
    # Runs a local RSMP site inside an Async reactor.
    class SupervisorTester < RSMP::Validator::Tester
      class << self
        attr_accessor :instance

        def connected(options = {}, &)
          instance.connected(options, &)
        end

        def reconnected(options = {}, &)
          instance.reconnected(options, &)
        end

        def disconnected(&)
          instance.disconnected(&)
        end

        def isolated(options = {}, &)
          instance.isolated(options, &)
        end
      end

      def parse_config
        @site_config = config['local_site']
        raise "config 'local_site' is missing" unless @site_config
      end

      def build_node(options)
        klass = case @site_config['type']
                when 'tlc'
                  RSMP::TLC::TrafficControllerSite
                else
                  RSMP::Site
                end
        site_settings = ConfigNormalizer.normalize_site_settings(@site_config.deep_merge(options))
        logger = create_site_logger(@site_config)
        @site = klass.new(
          site_settings: site_settings,
          logger: logger,
          collect: options['collect']
        )
      end

      def wait_for_connection
        log 'Waiting for connection to supervisor'
        @proxy = @node.find_supervisor :any
        @proxy.wait_for_state %i[connected ready], timeout: config['timeouts']['connect']
      rescue RSMP::TimeoutError
        raise RSMP::ConnectionError, "Could not connect to supervisor within #{config['timeouts']['connect']}s"
      end

      def wait_for_handshake
        @proxy.wait_for_state :ready, timeout: config['timeouts']['ready']
      rescue RSMP::TimeoutError
        raise RSMP::ConnectionError, "Handshake didn't complete within #{config['timeouts']['ready']}s"
      end

      def create_site_logger(site_config)
        log_settings = site_config.is_a?(Hash) ? site_config['log'] : nil
        logger_settings = RSMP::Validator.node_log_settings.merge('prefix' => '[TLC]       ')
        return RSMP::Logger.new(logger_settings) unless log_settings && !log_settings.empty?

        logger_settings.merge!(log_settings)
        logger_settings.delete('stream') if log_settings['path']
        RSMP::Logger.new(logger_settings)
      end
    end
  end
end
