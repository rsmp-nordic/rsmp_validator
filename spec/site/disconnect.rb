# Test how the site responds to various incorrect behaviour.
#
# The site object passed by TestSite a SiteProxy object. We can redefine methods
# on this object to modify behaviour after connection is established
#
# Note that we use TestSite.reconnect, rather than TestSite.connect,
# to ensure we get a fresh SiteProxy object each time.

RSpec.describe "RSMP site status" do

  let(:timeout) { 10 }

  it 'disconnects if watchdogs are not acknowledged' do
    TestSite.reconnected do |task,supervisor,site|
      def site.acknowledge original
      end
      expect { site.wait_for_state :stopping, timeout }.to_not raise_error
    end
  end

  it 'disconnects if no watchdogs are send' do
    TestSite.reconnected do |task,supervisor,site|
      def site.send_watchdog now=nil
      end
      expect { site.wait_for_state :stopping, timeout }.to_not raise_error
    end
  end

end
