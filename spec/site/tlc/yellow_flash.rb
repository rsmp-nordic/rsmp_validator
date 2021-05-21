RSpec.describe "Traffic Light Controller" do
  include StatusHelpers
  include CommandHelpers

  describe "Yellow Flash" do

    it 'M0001 set yellow flash', sxl: '>=1.0.7' do |example|
      Validator::Site.connected do |task,supervisor,site|
        prepare task, site

        timeout =  10

        switch_yellow_flash
        wait_for_groups 'c', timeout: timeout      # c mean s yellow flash

        switch_normal_control
        wait_for_groups '[^c]', timeout: timeout   # not c, ie. not yellow flash
      end
    end

  end
end

