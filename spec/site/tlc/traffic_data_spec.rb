RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::StatusHelpers

  describe "Traffic Data" do
    # Verify status S0201 traffic counting: number of vehicles
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'number of vehicles for a single detector is read with S0201', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "traffic counting: number of vehicles",
        { S0201: [:starttime,:vehicles] },
        Validator.config['components']['detector_logic'].keys.first
    end

    # Verify status S0205 traffic counting: number of vehicles
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'number of vehicles for all detectors is read with S0205', sxl: '>=1.0.14' do |example|
      request_status_and_confirm "traffic counting: number of vehicles",
        { S0205: [:start,:vehicles] }
    end

    # Verify status S0202 traffic counting: vehicle speed
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'vehicle speed for a single detector is read with S0202', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "traffic counting: vehicle speed",
        { S0202: [:starttime,:speed] },
        Validator.config['components']['detector_logic'].keys.first
    end

    # Verify status S0206 traffic counting: vehicle speed
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'vehicle speed for all detectors is read with S0206', sxl: '>=1.0.14' do |example|
      request_status_and_confirm "traffic counting: vehicle speed",
        { S0206: [:start,:speed] }
    end

    # Verify status S0203 traffic counting: occupancy
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'occupancy for a single detector is read with S0203', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "traffic counting: occupancy",
        { S0203: [:starttime,:occupancy] },
        Validator.config['components']['detector_logic'].keys.first
    end

    # Verify status S0207 traffic counting: occupancy
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'occupancy for all detectors is read with S0207', sxl: '>=1.0.14' do |example|
      request_status_and_confirm "traffic counting: occupancy",
        { S0207: [:start,:occupancy] }
    end

    # Verify status S0204 traffic counting: classification
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'classification for a single detector is read with S0204', sxl: '>=1.0.7' do |example|
      request_status_and_confirm "traffic counting: classification",
        { S0204: [
            :starttime,
            :P,
            :PS,
            :L,
            :LS,
            :B,
            :SP,
            :MC,
            :C,
            :F
        ] },
        Validator.config['components']['detector_logic'].keys.first
    end

    # Verify status S0208 traffic counting: classification
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'classification for all detectors is read with S0208', sxl: '>=1.0.14' do |example|
      request_status_and_confirm "traffic counting: classification",
        { S0208: [
            :start,
            :P,
            :PS,
            :L,
            :LS,
            :B,
            :SP,
            :MC,
            :C,
            :F
        ] }
    end
  end
end