# Experimental:
# Helper class for testing RSMP supervisors

require 'rsmp'
require 'singleton'
require 'colorize'

module Validator
  class SupervisorTester < Validator::Tester
    class << self
      attr_accessor :instance

      def connected(options = {}, &block)
        instance.connected(options, &block)
      end

      def reconnected(options = {}, &block)
        instance.reconnected(options, &block)
      end

      def disconnected(&block)
        instance.disconnected(&block)
      end

      def isolated(options = {}, &block)
        instance.isolated(options, &block)
      end
    end

    def parse_config
      @site_config = config['local_site']
      raise "config 'local_site' is missing" unless @site_config
    end

    # build local site
    def build_node(options)
      klass = case @site_config['type']
              when 'tlc'
                RSMP::TLC::TrafficControllerSite
              else
                RSMP::Site
              end
      site_settings = Validator::ConfigNormalizer.normalize_site_settings(@site_config)
      logger = create_site_logger(@site_config)
      @site = klass.new(
        site_settings: site_settings.deep_merge(options),
        logger: logger,
        collect: options['collect']
      )
    end

    def wait_for_connection
      Validator::Log.log 'Waiting for connection to supervisor'
      @proxy = @node.find_supervisor :any
      begin
        # wait for proxy to be connected (or ready)
        @proxy.wait_for_state %i[connected ready], timeout: config['timeouts']['connect']
      rescue RSMP::TimeoutError
        raise RSMP::ConnectionError, "Could not connect to supervisor within #{config['timeouts']['connect']}s"
      end
    end

    def wait_for_handshake
      # wait for handshake to be completed
      @proxy.wait_for_state :ready, timeout: config['timeouts']['ready']
    rescue RSMP::TimeoutError
      raise RSMP::ConnectionError, "Handshake didn't complete within #{config['timeouts']['ready']}s"
    end

    def create_site_logger(site_config)
      log_settings = site_config.is_a?(Hash) ? site_config['log'] : nil
      return Validator.logger unless log_settings && !log_settings.empty?

      logger_settings = Validator.logger.settings.dup
      logger_settings.merge!(log_settings)
      logger_settings.delete('stream') if log_settings['path']
      RSMP::Logger.new(logger_settings)
    end
  end
end
