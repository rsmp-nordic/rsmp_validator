RSpec.describe "RSMP site status" do
  status_response_timeout = SUPERVISOR_CONFIG['status_response_timeout']

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
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got signal group status after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
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
          {'sCI'=>status_code,'n'=>'detectorlogicstatus'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got detector logic status after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0003 input status'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0003'

      site.log "Requesting input status", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'inputstatus'},
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got input status after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0004 output status'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0004'

      site.log "Requesting output status", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'outputstatus'},
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got output status after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0005 traffic controller starting'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0005'

      site.log "Requesting traffic controller starting (true/false)", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got traffic controller starting (true/false) after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0006 emergency stage'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0006'

      site.log "Requesting emergency stage status", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'},
          {'sCI'=>status_code,'n'=>'emergencystage'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got emergency stage status after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0007 controller switched on (dark mode=off)'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0007'

      site.log "Requesting controller switch on (dark mode=off)", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'},
          {'sCI'=>status_code,'n'=>'intersection'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got controller switched on status (dark mode=off) after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0008 manual control'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0008'

      site.log "Requesting manual control status", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'},
          {'sCI'=>status_code,'n'=>'intersection'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got manual control status after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0009 fixed time control'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0009'

      site.log "Requesting fixed time control status", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'},
          {'sCI'=>status_code,'n'=>'intersection'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got fixed time control status after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0010 isolated control'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0010'

      site.log "Requesting isloated control status", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'},
          {'sCI'=>status_code,'n'=>'intersection'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got isolated control status after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0011 yellow flash'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0011'

      site.log "Requesting yellow flash status", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'},
          {'sCI'=>status_code,'n'=>'intersection'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got yellow flash status after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0012 all red'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0012'

      site.log "Requesting 'all red' status", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'},
          {'sCI'=>status_code,'n'=>'intersection'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got 'all red' status after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
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
        message, response = site.request_status component, [{'sCI'=>status_code,'n'=>status_name}], status_response_timeout
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

      expect(item["q"]).to eq('recent')
    end
  end

  it 'S0014 current time plan'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0014'

      site.log "Requesting current time plan", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got current time plan after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0015 current traffic situation'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0015'

      site.log "Requesting current traffic situation", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got current traffic situation after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0016 number of detector logics'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0016'

      site.log "Requesting number of detector logics", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'number'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got number of detector logics after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0017 number of signal groups'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0017'

      site.log "Requesting number of signal groups", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'number'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got number of signal groups after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0018 number of time plans'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0018'

      site.log "Requesting number of time plans", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'number'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got number of time plans after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0019 number of traffic situations'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0019'

      site.log "Requesting number of traffic situations", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'number'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got number of traffic situations after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0020 control mode'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0020'

      site.log "Requesting control mode", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'controlmode'},
          {'sCI'=>status_code,'n'=>'intersection'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got control mode after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0021 manually set detector logic'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0021'

      site.log "Requesting manually set detector logics", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'detectorlogics'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got manually set detector logics after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0022 list of time plans'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0022'

      site.log "Requesting list of time plans", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got list of time plans after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0023 command table'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0023'

      site.log "Requesting command table", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got command table after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0024 offset time'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0024'

      site.log "Requesting offset time", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got offset time after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0025 time-of-green/time-of-red' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = COMPONENT_CONFIG['signal_group'].keys.first
      status_code = 'S0025'

      site.log "Requesting time-of-green/time-of-red", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'minToGEstimate'},
          {'sCI'=>status_code,'n'=>'maxToGEstimate'},
          {'sCI'=>status_code,'n'=>'likelyToGEstimate'},
          {'sCI'=>status_code,'n'=>'ToGConfidence'},
          {'sCI'=>status_code,'n'=>'minToREstimate'},
          {'sCI'=>status_code,'n'=>'maxToREstimate'},
          {'sCI'=>status_code,'n'=>'likelyToREstimate'},
          {'sCI'=>status_code,'n'=>'ToRConfidence'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got time-of-green/time-of-red after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0026 week time table'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0026'

      site.log "Requesting week time table", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got week time table after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0027 time tables'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0027'

      site.log "Requesting command table", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got time table after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end

  end

  it 'S0028 cycle time' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0028'

      site.log "Requesting cycle time", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got cycle time after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0029 forced input status' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0029'

      site.log "Requesting forced input status", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got forced input status after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0030 forced output status' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0030'

      site.log "Requesting forced output status", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got forced output status after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0031 trigger level sensitivity for loop detector' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0031'

      site.log "Requesting trigger level sensitivity for loop detector", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got trigger level sensitivity for loop detector after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0091 operator logged in/out OP-panel' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0091'

      site.log "Requesting operator logged in/out OP-panel", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'},
          {'sCI'=>status_code,'n'=>'user'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got operator logged in/out OP-panel after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0092 operator logged in/out web-interface' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0092'

      site.log "Requesting operator logged in/out web-interface", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'},
          {'sCI'=>status_code,'n'=>'user'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got operator logged in/out web-interface after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0095 version of traffic controller' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0095'

      site.log "Requesting version of traffic controller", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'status'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got version of traffic controller after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0096 current date and time'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0096'

      site.log "Requesting current date and time", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'year'},
          {'sCI'=>status_code,'n'=>'month'},
          {'sCI'=>status_code,'n'=>'day'},
          {'sCI'=>status_code,'n'=>'hour'},
          {'sCI'=>status_code,'n'=>'minute'},
          {'sCI'=>status_code,'n'=>'second'},
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got current date and time after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0097 version of traffic program' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0097'

      site.log "Requesting version of traffic program", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'version'},
          {'sCI'=>status_code,'n'=>'hash'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got version of traffic program after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0201 traffic counting: number of vehicles'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = COMPONENT_CONFIG['detector_logic'].keys.first
      status_code = 'S0201'

      site.log "Requesting traffic counting: number of vehicles", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'starttime'},
          {'sCI'=>status_code,'n'=>'vehicles'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got traffic counting: number of vehicles after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0202 traffic counting: vehicle speed' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = COMPONENT_CONFIG['detector_logic'].keys.first
      status_code = 'S0202'

      site.log "Requesting traffic counting: vehicle speed", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'starttime'},
          {'sCI'=>status_code,'n'=>'speed'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got traffic counting: vehicle speed after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0203 traffic counting: occupancy'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = COMPONENT_CONFIG['detector_logic'].keys.first
      status_code = 'S0203'

      site.log "Requesting traffic counting: occupancy", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'starttime'},
          {'sCI'=>status_code,'n'=>'occupancy'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got traffic counting: occupancy after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0204 traffic counting: classification' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = COMPONENT_CONFIG['detector_logic'].keys.first
      status_code = 'S0204'

      site.log "Requesting traffic counting: classification", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'starttime'},
          {'sCI'=>status_code,'n'=>'P'},
          {'sCI'=>status_code,'n'=>'PS'},
          {'sCI'=>status_code,'n'=>'L'},
          {'sCI'=>status_code,'n'=>'LS'},
          {'sCI'=>status_code,'n'=>'B'},
          {'sCI'=>status_code,'n'=>'SP'},
          {'sCI'=>status_code,'n'=>'MC'},
          {'sCI'=>status_code,'n'=>'C'},
          {'sCI'=>status_code,'n'=>'F'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got traffic counting: classification after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0205 traffic counting: number of vehicles'  do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0205'

      site.log "Requesting traffic counting: number of vehicles", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'start'},
          {'sCI'=>status_code,'n'=>'vehicles'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got traffic counting: number of vehicles after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0206 traffic counting: vehicle speed' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0206'

      site.log "Requesting traffic counting: vehicle speed", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'start'},
          {'sCI'=>status_code,'n'=>'speed'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got traffic counting: vehicle speed after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0207 traffic counting: occupancy' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0207'

      site.log "Requesting traffic counting: occupancy", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'start'},
          {'sCI'=>status_code,'n'=>'occupancy'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got traffic counting: occupancy after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end

  it 'S0208 traffic counting: classification' do |example|
    TestSite.log_test_header example
    TestSite.connected do |task,supervisor,site|
      component = MAIN_COMPONENT
      status_code = 'S0208'

      site.log "Requesting traffic counting: classification", level: :test
      start_time = Time.now
      message, response = nil,nil
      expect do
        message, response = site.request_status component,[
          {'sCI'=>status_code,'n'=>'start'},
          {'sCI'=>status_code,'n'=>'P'},
          {'sCI'=>status_code,'n'=>'PS'},
          {'sCI'=>status_code,'n'=>'L'},
          {'sCI'=>status_code,'n'=>'LS'},
          {'sCI'=>status_code,'n'=>'B'},
          {'sCI'=>status_code,'n'=>'SP'},
          {'sCI'=>status_code,'n'=>'MC'},
          {'sCI'=>status_code,'n'=>'C'},
          {'sCI'=>status_code,'n'=>'F'}
        ], status_response_timeout
      end.not_to raise_error

      expect(response).not_to be_a(RSMP::MessageNotAck), "Message rejected: #{response.attributes['rea']}"
      expect(response).to be_a(RSMP::StatusResponse)

      delay = Time.now - start_time
      site.log "Got traffic counting: classification after #{delay}s", level: :test

      expect(response.attributes["cId"]).to eq(component)
      expect(response.attributes["sS"]).to be_a(Array)

      response.attributes["sS"].each do |sS|
        expect(sS["q"]).to eq('recent')
      end
    end
  end
end
