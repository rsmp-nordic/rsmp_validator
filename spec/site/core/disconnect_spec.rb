RSpec.describe 'Site::Core' do

  # Check that the site closed the connection as required when faced with
  # various types of incorrect behaviour from our side.
  #
  # The site object passed by Validator::Site a SiteProxy object. We can redefine methods
  # on this object to modify behaviour after the connection has been established. To ensure
  # that the modfid SityProxy is not reused in later tests, we use  Validator::Site.isolate,
  # rather than the more common Validator::Site.connect.

  describe 'Connection' do
    # 1. Given the site is new and connected
    # 2. When site watchdog acknowledgement method is changed to do nothing
    # 3. Then the site should disconnect
    it 'is closed if watchdogs are not acknowledged', sxl: '>=1.0.7' do |example|
      Validator::Site.isolated do |task,supervisor,site|
        supervisor.ignore_errors RSMP::DisonnectError do
          def site.acknowledge original
          end
          timeout = Validator.config['timeouts']['disconnect']
          site.wait_for_state :stopped, timeout
        end
      rescue RSMP::TimeoutError
        raise "Site did not disconnect within #{timeout}s"
      end
    end

    # 1. Given the site is new and connected
    # 2. When site watchdog sending method is changed to do nothing
    # 3. Then the supervisor should disconnect
    it 'is closed if watchdogs are not received', sxl: '>=1.0.7' do |example|
      Validator::Site.isolated do |task,supervisor,site|
        supervisor.ignore_errors RSMP::DisonnectError do
          def site.send_watchdog now=nil
          end
          timeout = Validator.config['timeouts']['disconnect']
          site.wait_for_state :stopped, timeout
        end
      rescue RSMP::TimeoutError
        raise "Site did not disconnect within #{timeout}s"
      end
    end
  end
end