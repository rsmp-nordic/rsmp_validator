RSpec.describe 'Site::Core' do
  include Validator::CommandHelpers

  # Check that the site closed the connection as required when faced with
  # various types of incorrect behaviour from our side.
  #
  # The site object passed by Validator::Site a SiteProxy object. We can redefine methods
  # on this object to modify behaviour after the connection has been established. To ensure
  # that the modfid SityProxy is not reused in later tests, we use  Validator::Site.isolate,
  # rather than the more common Validator::Site.connect.

  describe 'Connection' do
    # 1. Given the site has just connected
    # 2. When our supervisor does not acknowledge watchdogs
    # 3. Then the site should disconnect
    it 'is closed if watchdogs are not acknowledged', sxl: '>=1.0.7' do |example|
      timeout = Validator.config['timeouts']['disconnect']
      Validator::Site.isolated do |task,supervisor,site_proxy|
        supervisor.ignore_errors RSMP::DisconnectError do
          log "Disabling watchdog acknowledgements, site should disconnect"
          def site_proxy.acknowledge original
            if original.is_a? RSMP::Watchdog
              log "Not acknowledgning watchdog", message: original
            else
              super
            end
          end
          site_proxy.wait_for_state :disconnected, timeout: timeout
        end
      rescue RSMP::TimeoutError
        raise "Site did not disconnect within #{timeout}s"
      end
    end

    # 1. Given the site has just connected
    # 2. When our supervisor stops sending watchdogs
    # 3. Then the site should not disconnect
    it 'is not closed if watchdogs are not received', sxl: '>=1.0.7', slow: true do |example|
      Validator::Site.isolated do |task,supervisor,site|
        timeout = Validator.config['timeouts']['disconnect']

        wait_task = task.async do
          site.wait_for_state :disconnected, timeout: timeout
          raise RSMP::DisconnectError
        rescue RSMP::TimeoutError
          # ok, no disconnect happened
        end

        log "Stop sending watchdogs, site should not disconnect"
        site.with_watchdog_disabled do
          wait_task.wait
        end
      end
    end
  end
end