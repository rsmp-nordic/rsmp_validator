module RSMP
  module Validator
    # Helper class for testing RSMP sites.
    # Runs a local RSMP supervisor inside an Async reactor.
    # Only one site is expected to connect to the supervisor.
    class SiteTester < RSMP::Validator::Tester
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

        def stop
          instance.stop
        end
      end

      def parse_config
        setup_supervisor_config
        validate_timeouts
      end

      def setup_supervisor_config
        @supervisor_config = config['local_supervisor']
        raise "config 'local_supervisor' is missing" unless @supervisor_config

        @supervisor_config['max_sites'] ||= 1
        @supervisor_config['sites'] ||= {}
        @supervisor_config['sites']['default'] ||= {}
        apply_security_codes
      end

      def apply_security_codes
        security_codes = config.dig('secrets', 'security_codes')
        return unless security_codes && !@supervisor_config['sites']['default']['security_codes']

        @supervisor_config['sites']['default']['security_codes'] = security_codes
      end

      def validate_timeouts
        %w[
          connect
          ready
          status_response
          status_update
          subscribe
          command
          command_response
          alarm
          disconnect
        ].each do |key|
          raise "config 'timeouts/#{key}' is missing" unless config['timeouts'][key]
        end
      end

      def build_node(options)
        logger = create_supervisor_logger(@supervisor_config)
        supervisor_settings = ConfigNormalizer.normalize_supervisor_settings(
          @supervisor_config.deep_merge(rsmp_node_options(options))
        )

        RSMP::Supervisor.new(
          supervisor_settings: supervisor_settings,
          logger: logger,
          collect: options['collect']
        )
      end

      def wait_for_connection
        @proxy = @node.proxies.first
        return if @proxy

        log 'Waiting for site to connect'
        @proxy = @node.wait_for_site(:any, timeout: config['timeouts']['connect'])
      rescue RSMP::TimeoutError
        raise RSMP::ConnectionError, "Site did not connect within #{config['timeouts']['connect']}s"
      end

      def wait_for_handshake
        return if @proxy.ready?

        log 'Waiting for handshake to complete'
        @proxy.wait_for_state :ready, timeout: config['timeouts']['ready']
        log 'Ready'
        return if @initial_unsubscribe_done

        @proxy.unsubscribe_from_all component: RSMP::Validator.get_config('main_component')
        @initial_unsubscribe_done = true
      end

      def create_supervisor_logger(supervisor_config)
        log_settings = supervisor_config.is_a?(Hash) ? supervisor_config['log'] : nil
        logger_settings = RSMP::Validator.node_log_settings.merge('prefix' => '[SUPERVISOR]')
        return RSMP::Logger.new(logger_settings) unless log_settings && !log_settings.empty?

        logger_settings.merge!(log_settings)
        logger_settings.delete('stream') if log_settings['path']
        RSMP::Logger.new(logger_settings)
      end

      def rsmp_node_options(options)
        options.except('collect')
      end
    end
  end
end
