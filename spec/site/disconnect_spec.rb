# Test how the site responds to various incorrect behaviour.
#
# The site object passed by TestSite a SiteProxy object. We can redefine methods
# on this object to modify behaviour after connection is established
#
# Note that we use TestSite.isolate, rather than TestSite.connect,
# to ensure we get a fresh SiteProxy object each time, and that it's not reused in
# later tests

RSpec.describe "RSMP site disconnect" do
  it 'disconnects if watchdogs are not acknowledged', sxl: '>=1.0.7' do |example|
    TestSite.isolated do |task,supervisor,site|
      def site.acknowledge original
      end
      #expect { site.wait_for_state :stopping, 60 }.to_not raise_error
    end
  end

  it 'disconnects if no watchdogs are send', sxl: '>=1.0.7' do |example|
    TestSite.isolated do |task,supervisor,site|
      def site.send_watchdog now=nil
      end
      #expect { site.wait_for_state :stopping, 180 }.to_not raise_error
    end
  end

end
