RSpec.describe 'RSMP site commands' do
  it 'responds to valid command request' do
    TestSite.connected do |task,supervisor,site|
      # TODO
      # compoments should be read from a config, or fetched from the site
      # list of commands and parameters should be read from an SXL specification (in JSON Schema?)
      component = 'AA+BBCCC=DDDEE002'
      command_code = 'M0001'
      command_name = 'status'

      site.send_command component, [{'cCI' => command_code,'n' => command_name,'cO' => '', 'v' => 'NormalControl'}]
      response = site.wait_for_command_response component: component, timeout: 1
      expect(response).to be_a(RSMP::CommandResponse)
      expect(response.attributes['cId']).to eq(component)
      expect(response.attributes['rvs']).to eq([{'age'=>'recent', 'cCI'=>command_code, 'n'=>command_name, 'v'=>'NormalControl'}])
    end
  end
end
