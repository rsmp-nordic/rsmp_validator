def unsubscribe_from_all task,supervisor,site
  message, response = site.unsubscribe_to_status @component, [
    {'sCI'=>'S0014','n'=>'status'},
    {'sCI'=>'S0001','n'=>'signalgroupstatus'},
    {'sCI'=>'S0001','n'=>'cyclecounter'},
    {'sCI'=>'S0001','n'=>'basecyclecounter'},
    {'sCI'=>'S0001','n'=>'stage'}
  ]
end

def subscribe task,supervisor,site
  message, response = site.subscribe_to_status @component, [{'sCI'=>@status_code_id,'n'=>@status_name,'uRt'=>'1'}], 180
end

def set_plan task,supervisor,site, plan
  status = 'True'
  securityCode = SECRETS['securityCodes'][2]

  site.log "Switching to plan #{plan}", level: :test
  start_time = Time.now
  site.send_command @component, [
    {'cCI' => @command_code_id, 'cO' => @command_name, 'n' => 'status', 'v' => status},
    {'cCI' => @command_code_id, 'cO' => @command_name, 'n' => 'securityCode', 'v' => securityCode},
    {'cCI' => @command_code_id, 'cO' => @command_name, 'n' => 'timeplan', 'v' => plan}
  ]

  site.log "Waiting for command response confirming intention to switch to plan #{plan}", level: :test
  response = site.wait_for_command_response component: @component, timeout: 180

  expect(response).to be_a(RSMP::CommandResponse)
  expect(response.attributes['cId']).to eq(@component)

  age = 'recent'
  expect(response.attributes['rvs']).to eq([
    { 'cCI' => @command_code_id, 'n' => 'status','v' => status, 'age' => age },
    { 'cCI' => @command_code_id, 'n' => 'securityCode','v' => securityCode, 'age' => age },
    { 'cCI' => @command_code_id, 'n' => 'timeplan','v' => plan, 'age' => age }
  ])

  delay = Time.now - start_time
  site.log "Intention to switch to plan #{plan} confirmed after #{delay.to_i}s", level: :test
end

def get_status_value message
  message.attributes['sS'].first['s']
end

def switch task,supervisor,site,plan
  set_plan task,supervisor,site, plan
  site.log "Waiting for status update that confirms switch to plan #{plan}", level: :test
  start_time = Time.now
  response = site.wait_for_status_update component: @component, sCI: @status_code_id, n: @status_name, q:'recent', s: plan, timeout: 180
  current_plan = get_status_value response
  expect(current_plan).to eq(plan)
  delay = Time.now - start_time
  site.log "Switch to plan #{plan} confirmed after #{delay.to_i}s", level: :test
end

RSpec.describe 'RSMP site commands' do
  it 'responds to valid command request' do
    @component = MAIN_COMPONENT

    @command_code_id = 'M0002'
    @command_name = 'setPlan'

    @status_code_id = 'S0014'
    @status_name = 'status'

    plans = SITE_CONFIG['plans']

    TestSite.connected do |task,supervisor,site|
      unsubscribe_from_all task,supervisor,site
      subscribe task,supervisor,site
      plans.each do |plan|
        switch task,supervisor,site,plan
      end
    end
  end
end


