RSpec.describe 'Site::Traffic Light Controller' do
  include Validator::CommandHelpers
  include Validator::StatusHelpers

  describe 'System' do
    # Verify status S0091 operator logged in/out OP-panel
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'operator logged in/out of OP-panel is read with S0091', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        status_list = if RSMP::Proxy.version_meets_requirement?(site.sxl_version, '>=1.1')
                        { S0091: [:user] }
                      else
                        { S0091: %i[user status] }
                      end
        request_status_and_confirm site, 'operator logged in/out OP-panel', status_list
      end
    end

    # Verify status S0092 operator logged in/out web-interface
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'operator logged in/out of web-interface is read with S0092', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        status_list = if RSMP::Proxy.version_meets_requirement?(site.sxl_version, '>=1.1')
                        { S0092: [:user] }
                      else
                        { S0092: %i[user status] }
                      end
        request_status_and_confirm site, 'operator logged in/out web-interface', status_list
      end
    end

    # Verify status S0095 version of traffic controller
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    specify 'version is read with S0095 ', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'version of traffic controller',
                                   { S0095: [:status] }
      end
    end

    # 1. Verify connection
    # 2. Send control command to set securitycode_level
    # 3. Wait for status = true
    # 4. Send control command to setsecuritycode_level
    # 5. Wait for status = true
    specify 'security code is set with M0103', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        set_security_code 1
        set_security_code 2
      end
    end

    # Verify that the site responds with NotAck if we send incorrect security cdoes.
    # RThis hehaviour is defined in SXL >= 1.1. For earlier versions,
    # The behaviour is undefined.
    # 1. Given the site is connected
    # 2. When we send a M0008 command with incorrect security codes
    # 3. Then we should received a NotAck
    specify 'security code is rejected when incorrect', sxl: '>=1.1' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        expect { wrong_security_code }.to raise_error(RSMP::MessageRejected)
      end
    end
  end
end
