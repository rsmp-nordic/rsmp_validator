RSpec.describe "RSMP site status" do
  it 'S0001 signal group status' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0001'

      site.log "Requesting signal group status", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'signalgroupstatus'},
          {'sCI'=>status_code,'n'=>'cyclecounter'},
          {'sCI'=>status_code,'n'=>'basecyclecounter'},
          {'sCI'=>status_code,'n'=>'stage'}
        ], 180
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got signal group status after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
        expect(sS["s"]).to match(/[a-hA-G0-9NOP]*/) if sS["n"] == 'signalgroupstatus'
        expect(sS["s"]).to match(/[0-9]+/) if sS["n"] == 'cyclecounter'
        expect(sS["s"]).to match(/[0-9]+/) if sS["n"] == 'basecyclecounter'
        expect(sS["s"]).to match(/[0-9]+/) if sS["n"] == 'stage'
      end
    end
  end

  it 'S0002 detector logic status' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0002'

      site.log "Requesting detector logic status", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'detectorlogicstatus'},
        ], 180
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got detector logic status after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
        expect(sS["s"]).to match(/[0-9]+/) if sS["n"] == 'detectorlogicstatus'
      end
    end
  end

  it 'S0013 police key' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0013'
      status_name = 'status'

      site.log "Requesting police key", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component, [{'sCI'=>status_code,'n'=>status_name}], 180
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got police key after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      item = response.attributes["sS"].first

      expect(item["sCI"]).to eq(status_code)
      expect(item["n"]).to eq(status_name)

      expect(item["s"]).to match(/^[0-2](,[0-2])*$/)
      expect(item["q"]).to eq('recent')
    end
  end
end
