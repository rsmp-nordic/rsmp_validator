RSpec.describe "RSMP site status" do
  it 'responds with NotAck to invalid status request code' do
    TestSite.connected do |task,supervisor,site|

      site.log "Requesting non-existing status S0000", level: :test
      component = MAIN_COMPONENT
      status_code_id = 'S0000'
      status_name = 'bad'

      message, response = site.request_status component, [{'sCI'=>status_code_id,'n'=>status_name}], 60
      expect(response).to be_a(RSMP::MessageNotAck)
      expect(response.attributes['rea']).not_to be_nil
      expect(response.attributes['rea']).not_to be('')
    end
  end

  it 'responds with NotAck to invalid status request name' do
    TestSite.connected do |task,supervisor,site|

      site.log "Requesting non-existing status S0001 name", level: :test
      component = MAIN_COMPONENT
      status_code_id = 'S0001'
      status_name = 'bad'

      message, response = site.request_status component, [{'sCI'=>status_code_id,'n'=>status_name}], 60
      expect(response).to be_a(RSMP::MessageNotAck)
      expect(response.attributes['rea']).not_to be_nil
      expect(response.attributes['rea']).not_to be('')
    end
  end

end
