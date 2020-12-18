RSpec.describe "RSMP site status" do
  it 'responds with NotAck to invalid status request code' do |example|
    TestSite.connected do |task,supervisor,site|
      site.log "Requesting non-existing status S0000", level: :test
      response = site.fetch_status site.task, { component: MAIN_COMPONENT, 
        status_list: {S0000:[:status]},
        timeout: SUPERVISOR_CONFIG['command_response_timeout']
      }
      expect(response).to be_a(RSMP::MessageNotAck)
      expect(response.attributes['rea']).not_to be_nil
      expect(response.attributes['rea']).not_to be('')
    end
  end

  it 'responds with NotAck to invalid status request name' do |example|
    TestSite.connected do |task,supervisor,site|
      site.log "Requesting non-existing status S0001 name", level: :test
      response = site.fetch_status site.task, { component: MAIN_COMPONENT, 
        status_list: {S0000:[:bad]},
        timeout: SUPERVISOR_CONFIG['command_response_timeout']
      }
      expect(response).to be_a(RSMP::MessageNotAck)
      expect(response.attributes['rea']).not_to be_nil
      expect(response.attributes['rea']).not_to be('')
    end
  end

end
