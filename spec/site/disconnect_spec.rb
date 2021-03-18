# Test how the site responds to various incorrect behaviour.
#
# The site object passed by TestSite a SiteProxy object. We can redefine methods
# on this object to modify behaviour after the connection has been established.
#
# Note that we use TestSite.isolate, rather than TestSite.connect,
# to ensure we get a fresh SiteProxy object each time, so our deformed site proxy
# is not reused later tests

RSpec.describe "RSMP site disconnect" do

  # 1. Given the site is new and connected
  # 2. Change site watchdog acknowledgement method to do nothing
  # 3. Expect site to disconnect
  it 'disconnects if watchdogs are not acknowledged', sxl: '>=1.0.7' do |example|
    TestSite.isolated do |task,supervisor,site|
      def site.acknowledge original
      end
      site.wait_for_state :stopped, RSMP_CONFIG['disconnect_timeout']
    end
  end

  # 1. Given the site is new and connected
  # 2. Change site watchdog sending method to do nothing
  # 3. Expect supervisor to disconnect
  it 'disconnects if no watchdogs are send', sxl: '>=1.0.7' do |example|
    TestSite.isolated do |task,supervisor,site|
      def site.send_watchdog now=nil
      end
      site.wait_for_state :stopped, RSMP_CONFIG['disconnect_timeout']
    end
  end

end
