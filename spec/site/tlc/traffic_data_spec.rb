RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::StatusHelpers
  include Validator::CommandHelpers

  describe 'Traffic Data' do
    # Verify status S0201 traffic counting: number of vehicles
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'number of vehicles for a single detector is read with S0201', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'traffic counting: number of vehicles',
                                   { S0201: %i[starttime vehicles] },
                                   Validator.get_config('components', 'detector_logic').keys.first
      end
    end

    # Verify status S0205 traffic counting: number of vehicles
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'number of vehicles for all detectors is read with S0205', sxl: '>=1.0.14' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'traffic counting: number of vehicles',
                                   { S0205: %i[start vehicles] }
      end
    end

    # Verify status S0202 traffic counting: vehicle speed
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'vehicle speed for a single detector is read with S0202', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'traffic counting: vehicle speed',
                                   { S0202: %i[starttime speed] },
                                   Validator.get_config('components', 'detector_logic').keys.first
      end
    end

    # Verify status S0206 traffic counting: vehicle speed
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'vehicle speed for all detectors is read with S0206', sxl: '>=1.0.14' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'traffic counting: vehicle speed',
                                   { S0206: %i[start speed] }
      end
    end

    # Verify status S0203 traffic counting: occupancy
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'occupancy for a single detector is read with S0203', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'traffic counting: occupancy',
                                   { S0203: %i[starttime occupancy] },
                                   Validator.get_config('components', 'detector_logic').keys.first
      end
    end

    # Verify status S0207 traffic counting: occupancy
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'occupancy for all detectors is read with S0207', sxl: '>=1.0.14' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        result = wait_for_status task, 'traffic counting: occupancy',
                                 { S0207: %i[start occupancy] },
                                 update_rate: 60

        occupancies = result[:collector].matcher_got_hash.dig('S0207', 'occupancy')
        start = result[:collector].matcher_got_hash.dig('S0207', 'start')

        expect(occupancies).to be_a(String), 'Occupancies must be a string, but got nil'
        expect(start).to be_a(String), 'Start must be a string, but got nil'

        occupancies.split(',').each do |occupancy|
          num = occupancy.to_i
          expect((-1..100).cover?(num)).to be_truthy, "Occupancy must be in the range -1..100, got #{num}"
        end
      end
    end

    # Verify status S0204 traffic counting: classification
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'classification for a single detector is read with S0204', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'traffic counting: classification',
                                   { S0204: %i[
                                     starttime
                                     P
                                     PS
                                     L
                                     LS
                                     B
                                     SP
                                     MC
                                     C
                                     F
                                   ] },
                                   Validator.get_config('components', 'detector_logic').keys.first
      end
    end

    # Verify status S0208 traffic counting: classification
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'classification for all detectors is read with S0208', sxl: '>=1.0.14' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'traffic counting: classification',
                                   { S0208: %i[
                                     start
                                     P
                                     PS
                                     L
                                     LS
                                     B
                                     SP
                                     MC
                                     C
                                     F
                                   ] }
      end
    end
  end
end
