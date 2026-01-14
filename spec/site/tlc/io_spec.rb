# frozen_string_literal: true

RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::CommandHelpers
  include Validator::StatusHelpers

  # Tests related to inputs and outputs.

  describe 'IO' do
    describe 'Input' do
      # Verify that we can read input status with S0003, extendedinputstatus attribute
      # 1. Given the site is connected
      # 2. When we read input with S0029
      # 3. Then we should receive a valid response
      specify 'is read with S0003 with extended input status', sxl: '<1.2' do |_example|
        Validator::SiteTester.connected do |_task, _supervisor, site|
          request_status_and_confirm site, 'input status',
                                     { S0003: %i[inputstatus extendedinputstatus] }
        end
      end

      # Verify that we can read input status with S0003
      # 1. Given the site is connected
      # 2. When we read input with S0029
      # 3. Then we should receive a valid response
      specify 'is read with S0003', sxl: '>=1.2' do |_example|
        Validator::SiteTester.connected do |_task, _supervisor, site|
          request_status_and_confirm site, 'input status',
                                     { S0003: [:inputstatus] }
        end
      end

      # Verify that we can read forced input status with S0029
      # 1. Given the site is connected
      # 2. When we read input with S0029
      # 3. Then we should receive a valid response
      specify 'forcing is read with S0029', sxl: '>=1.0.13' do |_example|
        Validator::SiteTester.connected do |_task, _supervisor, site|
          request_status_and_confirm site, 'forced input status',
                                     { S0029: [:status] }
        end
      end

      # Verify that we can force input with M0019
      # 1. Given the site is connected
      # 2. And the input is forced off
      # 2. When we force the input on
      # 3. Then S0003 should show the input on

      specify 'forcing is set with M0019', sxl: '>=1.0.13' do |_example|
        Validator::SiteTester.connected do |task, _supervisor, site|
          prepare task, site
          inputs = Validator.get_config('items', 'inputs')
          skip('No inputs configured') if inputs.nil? || inputs.empty?
          inputs.each do |input|
            force_input input: input, status: 'True', value: 'False'
            force_input input: input, status: 'True', value: 'True'
          ensure
            force_input input: input, status: 'False', validate: false
          end
        end
      end

      # Verify that we can activate input with M0006
      # 1. Given the site is connected
      # 2. When we activate input with M0006
      # 3. Then S0003 should show the input is active
      # 4. When we deactivate input with M0006
      # 5. Then S0003 should show the input is inactive

      it 'is activated with M0006', sxl: '>=1.0.7' do |_example|
        Validator::SiteTester.connected do |task, _supervisor, site|
          prepare task, site
          inputs = Validator.get_config('items', 'inputs')
          skip('No inputs configured') if inputs.nil? || inputs.empty?
          prepare task, site
          inputs.each { |input| switch_input input }
        end
      end

      # Verify that we can acticate/deactivate a series of inputs with M0013
      # 1. Given the site is connected
      # 2. Send control command to set a serie of input
      # 3. Wait for status = true
      specify 'series is activated with M0013', sxl: '>=1.0.8' do |_example|
        Validator::SiteTester.connected do |task, _supervisor, site|
          prepare task, site
          inputs = Validator.get_config('items', 'inputs')
          skip('No inputs configured') if inputs.nil? || inputs.empty?
          status = '1,3,12;5,5,10'
          apply_series_of_inputs status
        end
      end

      # Verify that input sensitivity can be set with M0021
      # 1. Given the site is connected
      # 2. When we set sensitivity with M0021
      # 3. Then we receive a confirmation
      specify 'sensitivity is set with M0021', sxl: '>=1.0.15' do |_example|
        Validator::SiteTester.connected do |task, _supervisor, site|
          prepare task, site
          status = '1-50'
          apply_trigger_level status
        end
      end
    end

    describe 'Output' do
      # Verify that  output status can be read with S0004, extended output status
      # 1. Given the site is connected
      # 2. When we subscribe to S0004
      # 3. We should receive a status updated
      # 4. And the outputstatus attribute should be a digit string
      specify 'is read with S0004', sxl: ['>=1.0.7', '<1.2'] do |_example|
        Validator::SiteTester.connected do |task, _supervisor, site|
          prepare task, site
          request_status_and_confirm site, 'output status',
                                     { S0004: %i[outputstatus extendedoutputstatus] }
        end
      end

      # Verify that  output status can be read with S0004
      # 1. Given the site is connected
      # 2. When we subscribe to S0004
      # 3. We should receive a status updated
      # 4. And the outputstatus attribute should be a digit string
      specify 'is read with S0004', sxl: ['>=1.2'] do |_example|
        Validator::SiteTester.connected do |task, _supervisor, site|
          prepare task, site
          request_status_and_confirm site, 'output status',
                                     { S0004: [:outputstatus] }
        end
      end

      # Verify that forced output status can be read with S0030
      # 1. Given the site is connected
      # 2. Request status
      # 3. Expect status response before timeout
      specify 'forcing is read with S0030', sxl: '>=1.0.15' do |_example|
        Validator::SiteTester.connected do |task, _supervisor, site|
          prepare task, site
          request_status_and_confirm site, 'forced output status',
                                     { S0030: [:status] }
        end
      end

      # Verify that output can be forced with M0020
      # 1. Given the site is connected
      # 2. When we force output with M0020
      # 3. Wait for status = true
      specify 'forcing is set with M0020', sxl: '>=1.0.15' do |_example|
        Validator::SiteTester.connected do |task, _supervisor, site|
          prepare task, site
          outputs = Validator.get_config('items', 'outputs')
          skip('No outputs configured') if outputs.nil? || outputs.empty?
          outputs.each do |output|
            force_output output: output, status: 'True', value: 'True'
            force_output output: output, status: 'True', value: 'False'
          ensure
            force_output output: output, status: 'False', validate: false
          end
        end
      end
    end
  end
end
