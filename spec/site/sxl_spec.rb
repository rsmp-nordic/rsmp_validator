RSpec.describe 'RSMP site commands' do  
  include CommandHelpers
  include StatusHelpers

  it 'M0001 set yellow flash', sxl: ['>=1.0.7','<1.0.13'] do |example|
    TestSite.connected do |task,supervisor,site|
      prepare task, site
      switch_yellow_flash
      switch_normal_control
    end
  end
end