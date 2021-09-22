RSpec.describe 'Traffic Light Controller' do  
  include CommandHelpers
  include StatusHelpers

  it 'try to trigger NotReady' do |example|
    Validator::Site.connected do |task,supervisor,site|
      task.sleep 2
      site.request_aggregated_status Validator.config['main_component']
    end
  end

end