RSpec.describe "RSMP site status" do
  it 'responds to valid status request' do
    TestSite.connected do |task,supervisor,site|
      component = 'KK+AG9998=001TC000'
      status_code = 'S0001'
      status_name = 'signalgroupstatus'

      message, response = site.subscribe_to_status component, [{'sCI'=>status_code,'n'=>status_name,'uRt'=>'0'}], RSMP_CONFIG['subscribe_timeout']

      expect(response).to be_a(RSMP::StatusUpdate)

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      item = response.attributes["sS"].first

      expect(item["sCI"]).to eq(status_code)
      expect(item["n"]).to eq(status_name)

      expect(item["s"]).to match(/[a-hA-G0-9NOP]*/)
      expect(item["q"]).to eq('recent')
    end
  end

end
