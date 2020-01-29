# Test command requests by sending commands and checking 
# responses and status updates

def log_confirmation action, &block
  @site.log "Confirming #{action}", level: :test
  start_time = Time.now
  yield block
  delay = Time.now - start_time
  upcase_first = action.sub(/\S/, &:upcase)
  @site.log "#{upcase_first} confirmed after #{delay.to_i}s", level: :test
end

def unsubscribe_from_all
  @site.unsubscribe_to_status @component, [
    {'sCI'=>'S0015','n'=>'status'},
    {'sCI'=>'S0014','n'=>'status'},
    {'sCI'=>'S0011','n'=>'status'},
    {'sCI'=>'S0009','n'=>'status'},
    {'sCI'=>'S0007','n'=>'status'},
    {'sCI'=>'S0006','n'=>'status'},
    {'sCI'=>'S0005','n'=>'status'},
    {'sCI'=>'S0001','n'=>'signalgroupstatus'},
    {'sCI'=>'S0001','n'=>'cyclecounter'},
    {'sCI'=>'S0001','n'=>'basecyclecounter'},
    {'sCI'=>'S0001','n'=>'stage'}
  ]
end

def subscribe status_list, update_rate: 1
  sub_list = status_list.map { |item| item.slice('sCI','n').merge 'uRt'=>update_rate.to_s }
  expect do
    @site.subscribe_to_status @component, sub_list, RSMP_CONFIG['subscribe_timeout']
  end.to_not raise_error
end

def set_plan plan
  status = 'True'
  security_code = SECRETS['security_codes'][2]

  @site.log "Switching to plan #{plan}", level: :test
  command_code_id = 'M0002'
  command_name = 'setPlan'
  @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'timeplan', 'v' => plan}
  ]

  log_confirmation "intention to switch to plan #{plan}" do
    response = nil
    expect do
      response = @site.wait_for_command_response component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'securityCode','v' => security_code, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'timeplan','v' => plan, 'age' => age }
    ])
  end
end

# Note the spelling error 'traficsituation'. This should be fixed in future version
def set_traffic_situation ts
  status = 'True'
  security_code = SECRETS['security_codes'][2]

  @site.log "Switching to traffic situation #{ts}", level: :test
  command_code_id = 'M0003'
  command_name = 'setTrafficSituation'
  @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'traficsituation', 'v' => ts}
  ]

  log_confirmation "intention to switch to traffic situation #{ts}" do
    response = nil
    expect do
      response = @site.wait_for_command_response component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'securityCode','v' => security_code, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'traficsituation','v' => ts, 'age' => age }
    ])
  end
end

def set_functional_position status
  timeout = '0'
  intersection = '0'
  security_code = SECRETS['security_codes'][2]

  @site.log "Switching to #{status}", level: :test
  command_code_id = 'M0001'
  command_name = 'setValue'
  @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'timeout', 'v' => timeout},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'intersection', 'v' => intersection}
  ]

  log_confirmation"intention to switch to #{status}" do
    response = nil
    expect do
      response = @site.wait_for_command_response component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'securityCode','v' => security_code, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'timeout','v' => timeout, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'intersection','v' => intersection, 'age' => age }
    ])
  end
end

def set_fixed_time status
  security_code = SECRETS['security_codes'][2]

  @site.log "Switching to fixed time #{status}", level: :test
  command_code_id = 'M0007'
  command_name = 'setFixedTime'
  @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code}
  ]

  log_confirmation"intention to switch to fixed time #{status}" do
    response = nil
    expect do
      response = @site.wait_for_command_response component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'securityCode','v' => security_code, 'age' => age }
    ])
  end
end

def set_restart
  status = 'True'
  security_code = SECRETS['security_codes'][2]

  @site.log "Restarting traffic controller", level: :test
  command_code_id = 'M0004'
  command_name = 'setRestart'
  @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code}
  ]

  log_confirmation "intention to restart traffic controller" do
    response = nil
    expect do
      response = @site.wait_for_command_response component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'securityCode','v' => security_code, 'age' => age },
    ])
  end
end

def set_emergency_route status, route
  security_code = SECRETS['security_codes'][2]

  @site.log "Set emergency route", level: :test
  command_code_id = 'M0005'
  command_name = 'setEmergency'
  @site.send_command @component, [
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'status', 'v' => status},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'securityCode', 'v' => security_code},
    {'cCI' => command_code_id, 'cO' => command_name, 'n' => 'emergencyroute', 'v' => route}
  ]

  log_confirmation "intention to switch to emergency route #{route}" do
    response = nil
    expect do
      response = @site.wait_for_command_response component: @component, timeout: RSMP_CONFIG['command_timeout']
    end.to_not raise_error

    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'securityCode','v' => security_code, 'age' => age },
      { 'cCI' => command_code_id, 'n' => 'emergencyroute','v' => route, 'age' => age }
    ])
  end
end

# TLC's with multiple intersections (rings) can respond with multiple statuses,
# e.g. "True,True" for two intersections
def multi_value value
  Array.new(SITE_CONFIG['intersections'],value).join(',')
end

def switch_plan plan
  set_plan plan
  verify_status({
    description: "switch to plan #{plan}",
    status_list: [{'sCI'=>'S0014','n'=>'status','status'=>plan}]
  })
end

def switch_traffic_situation ts
  set_traffic_situation ts
  verify_status({
    description: "switch to traffic situation #{ts}",
    status_list: [{'sCI'=>'S0015','n'=>'status','status'=>ts}]
  })
end

def verify_status status_list:, description:
  log_confirmation description do
    subscribe status_list
    status_list.each do |item|
      response = nil
      expect do
        response = @site.wait_for_status_update component: @component, sCI: item['sCI'],
          n: item['n'], q:'recent', s:item['status'], timeout: RSMP_CONFIG['status_timeout']
      end.to_not raise_error, "Did not receive status #{item.inspect}"
      expect(response[:status]['s']).to eq(item['status'])
    end
    unsubscribe_from_all
  end
end

def switch_yellow_flash
  set_functional_position 'YellowFlash'
  verify_status({
    description:"switch to yellow flash",
    status_list:[{'sCI'=>'S0011','n'=>'status','status'=>multi_value('True')}]
  })
end

def switch_dark_mode
  set_functional_position 'Dark'
  verify_status({
    description:"switch to dark mode",
    status_list:[{'sCI'=>'S0007','n'=>'status','status'=>multi_value('False')}]
  })
end

def wait_normal_control
  # Wait for 'switched on' to be true (dark mode false)
  verify_status({
    description:"dark mode off",
    status_list:[{'sCI'=>'S0007','n'=>'status','status'=>multi_value('True')}]
  })

  # Wait for yellow flash status to be false
  verify_status({
    description:"yellow flash off",
    status_list:[{'sCI'=>'S0011','n'=>'status','status'=>multi_value('False')}]
  })

  # Wait for startup mode to be false
  verify_status({
    description:"start-up mode off",
    status_list:[{'sCI'=>'S0005','n'=>'status','status'=>'False'}]
  })

  unsubscribe_from_all
end

def switch_normal_control
  set_functional_position 'NormalControl'
  wait_normal_control
end

def switch_fixed_time status
  set_fixed_time status
  verify_status({
    description:"switch to fixed time #{status}",
    status_list:[{'sCI'=>'S0009','n'=>'status','status'=>multi_value(status)}]
  })
end

def switch_emergency_route route
  set_emergency_route 'True',route
  verify_status({
    description:"activate emergency route #{route}",
    status_list:[{'sCI'=>'S0006','n'=>'status','status'=>'True','emergencystage'=>route}]
  })
  set_emergency_route 'False',route
  verify_status({
    description:"deactivate emergency route #{route}",
    status_list:[{'sCI'=>'S0006','n'=>'status','status'=>'False','emergencystage'=>route}]
  })
end

def prepare task, site
  @component = MAIN_COMPONENT
  @task = task
  @site = site
  unsubscribe_from_all
end

RSpec.describe 'RSMP site commands' do
  it 'M0001 set yellow flash' do |example|
    TestSite.log_test_header example
    TestSite.isolated do |task,supervisor,site|
      prepare task, site
      switch_yellow_flash
      switch_normal_control
    end
  end

  it 'M0001 set dark mode' do |example|
    TestSite.log_test_header example
    TestSite.isolated do |task,supervisor,site|
      prepare task, site
      switch_dark_mode
      switch_normal_control
    end
  end

  it 'M0002 set time plan' do |example|
    TestSite.log_test_header example
    TestSite.isolated do |task,supervisor,site|
      prepare task, site
      SITE_CONFIG['plans'].each { |plan| switch_plan plan }
    end
  end

  it 'M0003 set traffic situation' do |example|
    TestSite.log_test_header example
    TestSite.isolated do |task,supervisor,site|
      prepare task, site
      SITE_CONFIG['traffic_situation'].each { |ts| switch_traffic_situation ts }
    end
  end

  it 'M0004 restart' do |example|
    TestSite.log_test_header example
    TestSite.isolated do |task,supervisor,site|
      prepare task, site
      print "Testing traffic controller restart. Enter 'y' to continue, 'n' to skip: "
      response = $stdin.gets.chomp
      expect(response).to eq('y')

      set_restart
      expect { site.wait_for_state :stopping, 120}.to_not raise_error
    end
    TestSite.isolated do |task,supervisor,site|
      prepare task, site
      wait_normal_control
    end
  end

  it 'M0005 activate emergency route' do |example|
    TestSite.log_test_header example
    TestSite.isolated do |task,supervisor,site|
      prepare task, site
      SITE_CONFIG['emergency_route'].each { |route| switch_emergency_route route }
    end
  end

  it 'M0007 set fixed time' do |example|
    TestSite.log_test_header example
    TestSite.isolated do |task,supervisor,site|
      prepare task, site
      switch_fixed_time 'True'
      switch_fixed_time 'False'
    end
  end
end


