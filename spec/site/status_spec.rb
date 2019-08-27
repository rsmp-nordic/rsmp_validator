RSpec.describe "RSMP site status" do
  it 'responds to valid status request' do
    TestSite.connected do |task,supervisor,site|
      # TODO
      # compoments should be read from a config, or fetched from the site
      # list of commands and parameters should be read from an SXL specification (in JSON Schema?)
      component = 'AA+BBCCC=DDDEE002'
      status_code = 'S0001'
      status_name = 'count'

      message, response = site.request_status component, [{'sCI'=>status_code,'n'=>status_name}], 1
      expect(response).to be_a(RSMP::StatusResponse)
      expect(response.attributes["cId"]).to eq(component)

      copy = response.attributes["sS"].dup
      copy.each do |sS|
        sS["s"] = "1234" if sS["s"]
      end
      expect(copy).to eq( [{"n"=>status_name, "q"=>"recent", "sCI"=>status_code, "s"=>"1234"}] )
    end
  end

end
