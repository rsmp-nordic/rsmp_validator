describe 'Site::Tlc::Input' do
  include Validator::Helpers::Input
  include Validator::Helpers::Status

  # Tests related to inputs and outputs.

  # Verify that we can read input status with S0003, extendedinputstatus attribute
  # 1. Given the site is connected
  # 2. When we read input with S0029
  # 3. Then we should receive a valid response
  it 'is read with S0003 with extended input status' do
    with_site(:connected, sxl: '<1.2') do |site_proxy|
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status({ S0003: %i[inputstatus extendedinputstatus] }, within: timeout)
    end
  end

  # Verify that we can read input status with S0003
  # 1. Given the site is connected
  # 2. When we read input with S0029
  # 3. Then we should receive a valid response
  it 'is read with S0003' do
    with_site(:connected, sxl: '>=1.2') do |site_proxy|
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status({ S0003: [:inputstatus] }, within: timeout)
    end
  end

  # Verify that we can read forced input status with S0029
  # 1. Given the site is connected
  # 2. When we read input with S0029
  # 3. Then we should receive a valid response
  it 'forcing is read with S0029' do
    with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
      timeout = Validator.get_config('timeouts', 'status_response')
      site_proxy.request_status({ S0029: [:status] }, within: timeout)
    end
  end

  # Verify that we can force input with M0019
  # 1. Given the site is connected
  # 2. And the input is forced off
  # 2. When we force the input on
  # 3. Then S0003 should show the input on

  it 'forcing is set with M0019' do
    with_site(:connected, sxl: '>=1.0.13') do |site_proxy|
      inputs = Validator.get_config('items', 'inputs')
      skip('No inputs configured') if inputs.nil? || inputs.empty?
      inputs.each do |input|
        timeout = Validator.get_config('timeouts', 'command')
        site_proxy.force_input(input: input, status: 'True', value: 'False', within: timeout)
        site_proxy.force_input(input: input, status: 'True', value: 'True', within: timeout)
      ensure
        site_proxy.force_input(input: input, status: 'False', value: 'True')
      end
    end
  end

  # Verify that we can activate input with M0006
  # 1. Given the site is connected
  # 2. When we activate input with M0006
  # 3. Then S0003 should show the input is active
  # 4. When we deactivate input with M0006
  # 5. Then S0003 should show the input is inactive

  it 'is activated with M0006' do
    with_site(:connected, sxl: '>=1.0.7') do |site_proxy|
      inputs = Validator.get_config('items', 'inputs')
      skip('No inputs configured') if inputs.nil? || inputs.empty?
      inputs.each { |input| switch_input(site_proxy, input) }
    end
  end

  # Verify that we can acticate/deactivate a series of inputs with M0013
  # 1. Given the site is connected
  # 2. Send control command to set a serie of input
  # 3. Wait for status = true
  it 'series is activated with M0013' do
    with_site(:connected, sxl: '>=1.0.8') do |site_proxy|
      inputs = Validator.get_config('items', 'inputs')
      skip('No inputs configured') if inputs.nil? || inputs.empty?
      status = '1,3,12;5,5,10'
      timeout = Validator.get_config('timeouts', 'command')
      site_proxy.set_inputs(status, within: timeout)
    end
  end

  # Verify that input sensitivity can be set with M0021
  # 1. Given the site is connected
  # 2. When we set sensitivity with M0021
  # 3. Then we receive a confirmation
  it 'sensitivity is set with M0021' do
    with_site(:connected, sxl: '>=1.0.15') do |site_proxy|
      status = '1-50'
      site_proxy.set_trigger_level(status)
    end
  end
end
