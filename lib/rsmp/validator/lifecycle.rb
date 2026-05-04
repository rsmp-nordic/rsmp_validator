module Validator
  # Suite lifecycle: startup and shutdown of the Async reactor and auto nodes.
  module Lifecycle
    # Initialize the validator system at sus startup.
    def setup(sus_config)
      @verbose = sus_config.verbose?
      @log_stream = determine_log_stream(sus_config)
      determine_mode sus_config
      initialize_logging log_settings: {} # minimal init so log() works during config loading
      load_tester_config
      load_auto_node_config
      setup_logging # reinitialize with config-specific settings
      build_auto_node
      build_tester
    end

    # Determine the log stream based on sus config.
    def determine_log_stream(sus_config)
      if sus_config.respond_to?(:log_file_io) && sus_config.log_file_io
        sus_config.log_file_io
      elsif sus_config.respond_to?(:log_path) && sus_config.log_path
        File.open(sus_config.log_path, 'w')
      elsif sus_config.respond_to?(:log_to_stdout) && sus_config.log_to_stdout
        $stdout
      else
        File.open(File::NULL, 'w')
      end
    end

    # Set up logging with configuration-specific settings.
    def setup_logging
      settings = {
        'stream' => @log_stream,
        'color' => {
          'info' => 'light_black',
          'log' => 'white',
          'test' => 'white',
          'debug' => 'light_black'
        },
        'port' => true,
        'json' => true,
        'acknowledgements' => true,
        'watchdogs' => true,
        'test' => true,
        'debug' => true
      }
      settings = settings.deep_merge(config_log_settings) if config_log_settings
      settings = settings.deep_merge(config['log']) if config.is_a?(Hash) && config['log']
      initialize_logging log_settings: settings
    end

    # Called at sus startup: initializes the Async reactor and checks connectivity.
    def before_suite
      setup_reactor
      error = run_startup_checks
      raise error if error
    rescue RSMP::ConnectionError => e
      abort_startup(e, e.message)
    rescue StandardError => e
      abort_startup(e, e.inspect)
    end

    # Called at sus shutdown: stops the auto node and reactor.
    def after_suite
      reactor.run do |_task|
        auto_node&.stop
      ensure
        reactor.interrupt
      end
    rescue StandardError
      nil
    end

    # Initialize the Async reactor.
    def setup_reactor
      @reactor = Async::Reactor.new
      reactor.annotate 'reactor'
    end

    private

    def run_startup_checks
      error = nil
      reactor.run do |_task|
        auto_node&.start
        check_connection
      rescue StandardError => e
        error = e
      ensure
        reactor.interrupt
      end
      error
    end

    def abort_startup(exception, message)
      warn "Aborting: #{message}".colorize(:red)
      raise exception
    end
  end
end
