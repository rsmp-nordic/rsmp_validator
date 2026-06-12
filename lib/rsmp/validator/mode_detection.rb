module RSMP
  module Validator
    # Methods for detecting test mode and building the appropriate tester and auto node.
    module ModeDetection
      # Print an error message and exit.
      def abort_with_error(error)
        warn "Error: #{error}".colorize(:red)
        exit 1
      end

      # Initial connectivity check to verify we can connect to the site/supervisor being tested.
      def check_connection
        log "Initial #{mode} connection check"
        if mode == :site
          SiteTester.instance.connected { nil }
        elsif mode == :supervisor
          SupervisorTester.instance.connected { nil }
        end
      end

      # Set whether we are testing a site or a supervisor.
      def select_mode(mode)
        if self.mode
          abort_with_error 'Cannot run tests in both test/site/ and test/supervisor/' if self.mode != mode
          return
        end

        case mode
        when :site, :supervisor
          self.mode = mode
        else
          abort_with_error "Unknown test mode: #{mode}"
        end
      end

      # Determine mode from test file paths.
      def determine_mode(sus_config)
        paths = sus_config.paths.any? ? sus_config.paths : sus_config.test_paths
        site_dir = File.expand_path('test/site', sus_config.root)
        supervisor_dir = File.expand_path('test/supervisor', sus_config.root)

        paths.each do |path_str|
          expanded = File.expand_path(path_str, sus_config.root)
          inferred = infer_mode_from_path(expanded, site_dir, supervisor_dir)
          select_mode inferred if inferred
        end

        abort_with_error 'Could not determine test mode (site or supervisor) from test paths' unless mode
      end

      # Determine the test mode from a single expanded path.
      def infer_mode_from_path(path, site_dir, supervisor_dir)
        return :site if path == site_dir || path.start_with?("#{site_dir}/")
        return :supervisor if path == supervisor_dir || path.start_with?("#{supervisor_dir}/")

        nil
      end

      # Build the tester instance.
      def build_tester
        if mode == :site
          SiteTester.instance = SiteTester.new
        elsif mode == :supervisor
          SupervisorTester.instance = SupervisorTester.new
        else
          abort_with_error "Unknown test mode: #{mode}"
        end
      end

      # Build the auto node (local site or supervisor to be tested).
      def build_auto_node
        return unless auto_node_config

        if mode == :site
          self.auto_node = AutoSite.new
        elsif mode == :supervisor
          self.auto_node = AutoSupervisor.new
        else
          abort_with_error "Unknown test mode: #{mode}"
        end
      end
    end
  end
end
