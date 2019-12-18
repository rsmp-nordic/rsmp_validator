# Test command requests by sending commands and checking 
# responses and status updates

def log_confirmation action, &block
  @site.log "Waiting for confirmation of #{action}", level: :test
  start_time = Time.now
  yield block
  delay = Time.now - start_time
  @site.log "#{action.capitalize} confirmed after #{delay.to_i}s", level: :test
end

def unsubscribe_from_all
  message, response = @site.unsubscribe_to_status @component, [
    {'sCI'=>'S0014','n'=>'status'},
    {'sCI'=>'S0011','n'=>'status'},
    {'sCI'=>'S0007','n'=>'status'},
    {'sCI'=>'S0005','n'=>'status'},
    {'sCI'=>'S0001','n'=>'signalgroupstatus'},
    {'sCI'=>'S0001','n'=>'cyclecounter'},
    {'sCI'=>'S0001','n'=>'basecyclecounter'},
    {'sCI'=>'S0001','n'=>'stage'}
  ]
end

def subscribe
  message, response = @site.subscribe_to_status @component, [{'sCI'=>@status_code_id,'n'=>@status_name,'uRt'=>'1'}], 180
end

def set_plan plan
  status = 'True'
  securityCode = SECRETS['security_codes'][2]

  @site.log "Switching to plan #{plan}", level: :test
  start_time = Time.now
  @site.send_command @component, [
    {'cCI' => @command_code_id, 'cO' => @command_name, 'n' => 'status', 'v' => status},
    {'cCI' => @command_code_id, 'cO' => @command_name, 'n' => 'securityCode', 'v' => securityCode},
    {'cCI' => @command_code_id, 'cO' => @command_name, 'n' => 'timeplan', 'v' => plan}
  ]

  log_confirmation"intention to switch to plan #{plan}" do
    response = @site.wait_for_command_response component: @component, timeout: 180

    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => @command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => @command_code_id, 'n' => 'securityCode','v' => securityCode, 'age' => age },
      { 'cCI' => @command_code_id, 'n' => 'timeplan','v' => plan, 'age' => age }
    ])
  end
end

def set_functional_position status
  timeout = '0'
  intersection = '0'
  securityCode = SECRETS['security_codes'][2]

  @site.log "Switching to " + status, level: :test
  @site.send_command @component, [
    {'cCI' => @command_code_id, 'cO' => @command_name, 'n' => 'status', 'v' => status},
    {'cCI' => @command_code_id, 'cO' => @command_name, 'n' => 'securityCode', 'v' => securityCode},
    {'cCI' => @command_code_id, 'cO' => @command_name, 'n' => 'timeout', 'v' => timeout},
    {'cCI' => @command_code_id, 'cO' => @command_name, 'n' => 'intersection', 'v' => intersection}
  ]

  log_confirmation"intention to switch to  #{status}" do
    response = @site.wait_for_command_response component: @component, timeout: 180

    expect(response).to be_a(RSMP::CommandResponse)
    expect(response.attributes['cId']).to eq(@component)

    age = 'recent'
    expect(response.attributes['rvs']).to eq([
      { 'cCI' => @command_code_id, 'n' => 'status','v' => status, 'age' => age },
      { 'cCI' => @command_code_id, 'n' => 'securityCode','v' => securityCode, 'age' => age },
      { 'cCI' => @command_code_id, 'n' => 'timeout','v' => timeout, 'age' => age },
      { 'cCI' => @command_code_id, 'n' => 'intersection','v' => intersection, 'age' => age }
    ])
  end
end


def get_status_value message
  message.attributes['sS'].first['s']
end

# TLC's with multiple intersections (rings) can respond with multiple statuses,
# e.g. "True,True" for two intersections
def get_intersection_boolean boolean,intersections
  status = boolean
  while intersections > 1
    intersections = intersections - 1
    status = [ status,  boolean ].join(',')
  end
  status
end

def switch plan
  set_plan plan
  log_confirmation"intention to switch to plan #{plan}" do
    response = @site.wait_for_status_update component: @component, sCI: @status_code_id, n: @status_name, q:'recent', s: plan, timeout: 180
    current_plan = get_status_value response
    expect(current_plan).to eq(plan)
  end
end

def switch_yellow_flash intersections
  set_functional_position 'YellowFlash'
  log_confirmation "switch to yellow flash" do
    # Wait for yellow flash status to be true
    @status_code_id = 'S0011'
    @status_name = 'status'
    subscribe
    status = get_intersection_boolean 'True',intersections
    response = @site.wait_for_status_update component: @component, sCI: @status_code_id, n: @status_name, q:'recent', s:status, timeout: 180
    current_functional_position = get_status_value response
    expect(current_functional_position).to eq(status)
    unsubscribe_from_all
  end
end

def switch_dark_mode intersections
  set_functional_position task,supervisor,site,'Dark'
  log_confirmation "switch to dark nmode" do
    @status_code_id = 'S0007'
    @status_name = 'status'
    subscribe
    status = get_intersection_boolean 'False',intersections
    response = @site.wait_for_status_update component: @component, sCI: @status_code_id, n: @status_name, q:'recent', s:status, timeout: 180
    current_functional_position = get_status_value response
    expect(current_functional_position).to eq(status)
    unsubscribe_from_all
  end
end

def switch_normal_control intersections
  set_functional_position task,supervisor,site,'NormalControl'
  log_confirmation "switch to NormalControl" do
    # Wait for 'switched on' to be true (dark mode false)
    @status_code_id = 'S0007'
    @status_name = 'status'
    subscribe
    status = get_intersection_boolean 'True',intersections
    response = @site.wait_for_status_update component: @component, sCI: @status_code_id, n: @status_name, q:'recent', s:status, timeout: 180
    current_dark_mode = get_status_value response
    expect(current_dark_mode).to eq(status)
    unsubscribe_from_all

    # Wait for yellow flash status to be false
    @status_code_id = 'S0011'
    @status_name = 'status'
    subscribe
    status = get_intersection_boolean 'False',intersections
    response = @site.wait_for_status_update component: @component, sCI: @status_code_id, n: @status_name, q:'recent', s:status, timeout: 180
    current_dark_mode = get_status_value response
    expect(current_dark_mode).to eq(status)
    unsubscribe_from_all

    # Wait for startup mode to be false
    @status_code_id = 'S0005'
    @status_name = 'status'
    subscribe
    status = 'False'
    response = @site.wait_for_status_update component: @component, sCI: @status_code_id, n: @status_name, q:'recent', s:status, timeout: 180
    current_controller_starting = get_status_value response
    expect(current_controller_starting).to eq(status)
    unsubscribe_from_all
  end
end

RSpec.describe 'RSMP site commands' do
  it 'M0001 set yellow flash' do
    TestSite.connected do |task,supervisor,site|
      @component = MAIN_COMPONENT
      @command_code_id = 'M0001'
      @command_name = 'setValue'

      intersections = SITE_CONFIG['intersections']
      
      @task = task
      @supervisor = supervisor
      @site = site

      unsubscribe_from_all

      switch_yellow_flash intersections
      switch_normal_control intersections
    end
  end

  it 'M0001 set dark mode' do
    TestSite.connected do |task,supervisor,site|
      @component = MAIN_COMPONENT
      @command_code_id = 'M0001'
      @command_name = 'setValue'

      intersections = SITE_CONFIG['intersections']
      @task = task
      @supervisor = supervisor
      @site = site

      unsubscribe_from_all

      switch_dark_mode intersections
      switch_normal_control intersections
    end
  end

  it 'M0002 set time plan' do
    TestSite.connected do |task,supervisor,site|
      @component = MAIN_COMPONENT
      @command_code_id = 'M0002'
      @command_name = 'setPlan'

      @status_code_id = 'S0014'
      @status_name = 'status'

      plans = SITE_CONFIG['plans']
      
      unsubscribe_from_all
      subscribe
      plans.each do |plan|
        switch plan
      end
    end
  end
end


