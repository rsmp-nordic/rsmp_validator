# frozen_string_literal: true

RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::CommandHelpers
  include Validator::StatusHelpers

  describe 'Detector Logic' do
    # Verify status S0016 number of detector logics
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'list size is read with S0016', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'number of detector logics',
                                   { S0016: [:number] }
      end
    end

    # Verify status S0002 detector logic status
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'status is read with S0002', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'detector logic status',
                                   { S0002: [:detectorlogicstatus] }
      end
    end

    # Verify status S0021 manually set detector logic
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'forcing is read with S0021', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'detector logic forcing',
                                   { S0021: [:detectorlogics] }
      end
    end

    # 1. Verify connection
    # 2. Send control command to switch detector_logic= true
    # 3. Wait for status = true
    specify 'forcing is set with M0008', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site

        Validator.get_config('components', 'detector_logic').keys.each_with_index do |component, indx|
          force_detector_logic component, mode: 'True'
          wait_for_status(@task,
                          "detector logic #{component} to be True",
                          [{ 'sCI' => 'S0002', 'n' => 'detectorlogicstatus', 's' => /^.{#{indx}}1/ }])

          force_detector_logic component, mode: 'False'
          wait_for_status(@task,
                          "detector logic #{component} to be False",
                          [{ 'sCI' => 'S0002', 'n' => 'detectorlogicstatus', 's' => /^.{#{indx}}0/ }])
        end
      end
    end

    # Verify status S0031 trigger level sensitivity for loop detector
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'sensitivity is read with S0031', sxl: '>=1.0.15' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'loop detector sensitivity',
                                   { S0031: [:status] }
      end
    end
  end
end
