RSpec.describe "RSMP site status" do
  include StatusHelpers
  include CommandHelpers

  it 'M0001 set yellow flash' do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_yellow_flash
    end
  end

end
