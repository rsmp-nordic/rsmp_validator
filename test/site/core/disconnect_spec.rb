describe 'Site::Core' do
  # Check that the site closed the connection as required when faced with
  # various types of incorrect behaviour from our side.
  #
  # The site object passed by Validator::SiteTester a SiteProxy object. We can redefine methods
  # on this object to modify behaviour after the connection has been established. To ensure
  # that the modfid SityProxy is not reused in later tests, we use  Validator::SiteTester.isolate,
  # rather than the more common Validator::SiteTester.connect.

  describe 'Connection' do
    # 1. Given the site has just connected
    # 2. When our supervisor does not acknowledge watchdogs
    # 3. Then the site should disconnect
    it 'is closed if watchdogs are not acknowledged' do
      with_site(:isolated, sxl: '>=1.0.7') do |site_proxy|
        timeout = Validator.get_config('timeouts', 'disconnect')
        site_proxy.node.ignore_errors RSMP::DisconnectError do
          log 'Disabling watchdog acknowledgements, site should disconnect'
          def site_proxy.acknowledge(original)
            if original.is_a? RSMP::Watchdog
              log 'Not acknowledgning watchdog', message: original
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
    it 'is not closed if watchdogs are not received' do
      with_site(:isolated, sxl: '>=1.0.7') do |site_proxy|
        timeout = Validator.get_config('timeouts', 'disconnect')

        wait_task = Async::Task.current.async do
          site_proxy.wait_for_state :disconnected, timeout: timeout
          raise RSMP::DisconnectError
        rescue RSMP::TimeoutError
          # ok, no disconnect happened
        end

        log 'Stop sending watchdogs, site should not disconnect'
        site_proxy.with_watchdog_disabled do
          wait_task.wait
        end
      end
    end
  end
end
