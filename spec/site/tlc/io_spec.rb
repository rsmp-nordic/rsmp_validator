RSpec.describe 'Site::Traffic Light Controller' do  
  include Validator::CommandHelpers
  include Validator::StatusHelpers

  # Tests related to inputs and outputs.

  describe 'IO' do
    describe 'Input' do
      # Verify status S0029 forced input status
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      specify 'forcing is read with S0029', sxl: '>=1.0.13' do |example|
        request_status_and_confirm "forced input status",
          { S0029: [:status] }
      end

      # 1. Verify connection
      # 2. Send control command to set force input
      # 3. Wait for status = true  
      specify 'forcing is set with M0019', sxl: '>=1.0.13' do |example|
        Validator::Site.connected do |task,supervisor,site|

          prepare task, site

          input = Validator.config['items']['force_input']

          # force input to false
          status = 'True'  # forced
          inputValue = 'False'
          force_input status:status, input:input, value:inputValue
          
          # verify forced = 1
          wait_for_status(@task,
            "input #{input} to be forced",
            [{'sCI'=>'S0029','n'=>'status','s'=>/^.{#{input - 1}}1/}]
          )

          # verify inputstatus = 0
          wait_for_status(@task,
            "input #{input} to be #{inputValue}",
            [{'sCI'=>'S0003','n'=>'inputstatus','s'=>/^.{#{input - 1}}0/}]
          )

          
          # force input to true
          status = 'True'  # forced
          inputValue = 'True'
          force_input status:status, input:input, value:inputValue
          
          # verify forced = 1
          wait_for_status(@task,
            "input #{input} to be forced",
            [{'sCI'=>'S0029','n'=>'status','s'=>/^.{#{input - 1}}1/}]
          )

          # verify inputstatus = 1
          wait_for_status(@task,
            "input #{input} to be to #{inputValue}",
            [{'sCI'=>'S0003','n'=>'inputstatus','s'=>/^.{#{input - 1}}1/}]
          )


          # release input
          status = 'False'  # unforced
          inputValue = 'False'
          force_input status:status, input:input, value:inputValue

          # verify force = 0
          wait_for_status(@task,
            "input #{input} to be released",
            [{'sCI'=>'S0029','n'=>'status','s'=>/^.{#{input - 1}}0/}]
          )

        end
      end    

      # 1. Verify connection
      # 2. Verify that there is a Validator.config['validator'] with a input
      # 3. Send control command to switch input
      # 4. Wait for status "input" = requested  
      it 'is activated with M0006', sxl: '>=1.0.7' do |example|
        inputs = Validator.config['items']['inputs']
        skip("No inputs configured") if inputs.nil? || inputs.empty?
        Validator::Site.connected do |task,supervisor,site|
          prepare task, site
          inputs.each { |input| switch_input input }
        end
      end

      # 1. Verify connection
      # 2. Send control command to set a serie of input
      # 3. Wait for status = true  
      specify 'series is activated with M0013', sxl: '>=1.0.8' do |example|
        Validator::Site.connected do |task,supervisor,site|
          status = "3,4143,65;12,1,4"
          prepare task, site
          set_series_of_inputs status
        end
      end

      # 1. Verify connection
      # 2. Send control command to set trigger level
      # 3. Wait for status = true  
      specify 'sensitivity is set with M0021', sxl: '>=1.0.15' do |example|
        Validator::Site.connected do |task,supervisor,site|
          prepare task, site
          status = '1-50'
          set_trigger_level status
        end
      end
    end

    describe 'Output' do
      # Verify status S0030 forced output status
      #
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      specify 'forcing is read with S0030', sxl: '>=1.0.15' do |example|
        request_status_and_confirm "forced output status",
          { S0030: [:status] }
      end

      # 1. Verify connection
      # 2. Send control command to set force ounput
      # 3. Wait for status = true
      specify 'forcing is set with M0020', sxl: '>=1.0.15' do |example|
        Validator::Site.connected do |task,supervisor,site|
          status = 'False'
          output = 1
          outputValue = 'True'
          prepare task, site
          force_output status, output, outputValue
        end
      end
    end
  end
end
