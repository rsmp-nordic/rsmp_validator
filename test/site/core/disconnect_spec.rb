describe 'Site::Core' do
  # Check that the site closed the connection as required when faced with
  # various types of incorrect behaviour from our side.
  #
  # The site object passed by RSMP::Validator::SiteTester a SiteProxy object. We can redefine methods
  # on this object to modify behaviour after the connection has been established. To ensure
  # that the modfid SityProxy is not reused in later tests, we use  RSMP::Validator::SiteTester.isolate,
  # rather than the more common RSMP::Validator::SiteTester.connect.

  describe 'Connection' do
    # 1. Given the site has just connected
    # 2. When our supervisor does not acknowledge watchdogs
    # 3. Then the site should disconnect
    it 'is closed if watchdogs are not acknowledged' do
      with_site(:isolated, sxl: '>=1.0.7') do |site_proxy|
        timeout = RSMP::Validator.get_config('timeouts', 'disconnect')
        log 'Disabling watchdog acknowledgements, site should disconnect'
        def site_proxy.acknowledge(original)
          if original.is_a? RSMP::Watchdog
            log 'Not acknowledgning watchdog', message: original
          else
            super
          end
        end
        site_proxy.wait_for_state!(:disconnected, timeout: timeout)
      end
    end

    # 1. Given the site has just connected
    # 2. When our supervisor stops sending watchdogs
    # 3. Then the site should not disconnect
    it 'is not closed if watchdogs are not received' do
      with_site(:isolated, sxl: '>=1.0.7') do |site_proxy|
        timeout = RSMP::Validator.get_config('timeouts', 'disconnect')

        log 'Stop sending watchdogs, site should not disconnect'
        site_proxy.with_watchdog_disabled do
          result = site_proxy.wait_for_state :disconnected, timeout: timeout
          assert(result.failure? && result.failure.code == :timeout,
                 "Site disconnected unexpectedly: #{result.inspect}")
        end
      end
    end
  end
end
