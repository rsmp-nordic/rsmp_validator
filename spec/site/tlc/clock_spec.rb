RSpec.describe Site::Tlc::Clock do
  include Validator::CommandHelpers
  include Validator::StatusHelpers
  include Validator::ProgrammingHelpers

  # Tests related to the clock.
  # When you set the clock, the adjusted time should be used
  # everywhere you get back a timestamp.
  # Note that watchdog messages can be used to synchronize the clock,
  # which can interfere with our tests. So we disable sending watchdogs
  # during tests.

  describe 'Clock' do
    let(:clock) { Time.new(2020, 9, 29, 17, 29, 51, '+00:00') }

    # Verify status 0096 current date and time
    #
    # 1. Given the site is connected
    # 2. Request status
    # 3. Expect status response before timeout
    it 'can be read with S0096', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |_task, _supervisor, site|
        request_status_and_confirm site, 'current date and time',
                                   { S0096: %i[
                                     year
                                     month
                                     day
                                     hour
                                     minute
                                     second
                                   ] }
      end
    end

    # Verify that the controller responds to M0104
    #
    # 1. Given the site is connected
    # 2. Send command
    # 3. Expect status response before timeout
    it 'can be set with M0104', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        apply_clock(clock)
      end
    end

    # Verify status S0096 clock after changing clock
    #
    # 1. Given the site is connected
    # 2. Send control command to set_clock
    # 3. Request status S0096
    # 4. Compare set_clock and status timestamp
    # 5. Expect the difference to be within max_diff
    it 'is used for S0096 status response', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        site.with_watchdog_disabled do # avoid time synchronization by disabling watchdogs
          with_clock_set site, clock do
            status_list = { S0096: %i[
              year
              month
              day
              hour
              minute
              second
            ] }
            result = site.request_status(
              Validator.get_config('main_component'),
              convert_status_list(status_list),
              collect!: {
                timeout: Validator.get_config('timeouts', 'status_update')
              }
            )
            collector = result[:collector]
            status = status_list.keys.first.to_s

            received = Time.new(
              collector.matcher_result({ 'sCI' => status, 'n' => 'year' })['s'],
              collector.matcher_result({ 'sCI' => status, 'n' => 'month' })['s'],
              collector.matcher_result({ 'sCI' => status, 'n' => 'day' })['s'],
              collector.matcher_result({ 'sCI' => status, 'n' => 'hour' })['s'],
              collector.matcher_result({ 'sCI' => status, 'n' => 'minute' })['s'],
              collector.matcher_result({ 'sCI' => status, 'n' => 'second' })['s'],
              'UTC'
            )

            max_diff =
              Validator.get_config('timeouts', 'command_response') +
              Validator.get_config('timeouts', 'status_response')

            diff = received - clock
            diff = diff.round
            expect(diff.abs).to be <= max_diff,
                                "Clock reported by S0096 is off by #{diff}s, should be within #{max_diff}s"
          end
        end
      end
    end

    # Verify status response timestamp after changing clock
    #
    # 1. Given the site is connected
    # 2. Send control command to set_clock
    # 3. Request status S0096
    # 4. Compare set_clock and response timestamp
    # 5. Expect the difference to be within max_diff
    it 'is used for S0096 response timestamp', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        site.with_watchdog_disabled do # avoid time synchronization by disabling watchdogs
          with_clock_set site, clock do
            status_list = { S0096: %i[
              year
              month
              day
              hour
              minute
              second
            ] }

            result = site.request_status Validator.get_config('main_component'),
                                         convert_status_list(status_list),
                                         collect!: {
                                           timeout: Validator.get_config('timeouts', 'status_response')
                                         }
            collector = result[:collector]

            max_diff = Validator.get_config('timeouts',
                                            'command_response') + Validator.get_config('timeouts', 'status_response')
            diff = Time.parse(collector.messages.first.attributes['sTs']) - clock
            diff = diff.round
            expect(diff.abs).to be <= max_diff,
                                "Timestamp of S0096 is off by #{diff}s, should be within #{max_diff}s"
          end
        end
      end
    end

    # Verify aggregated status response timestamp after changing clock
    #
    # 1. Given the site is connected
    # 2. Send control command to set clock
    # 3. Wait for status = true
    # 4. Request aggregated status
    # 5. Compare set_clock and response timestamp
    # 6. Expect the difference to be within max_diff
    it 'is used for aggregated status timestamp', core: '>=3.1.5', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        site.with_watchdog_disabled do # avoid time synchronization by disabling watchdogs
          with_clock_set site, clock do
            result = site.request_aggregated_status Validator.get_config('main_component'), collect!: {
              timeout: Validator.get_config('timeouts', 'status_response')
            }
            collector = result[:collector]
            max_diff = Validator.get_config('timeouts',
                                            'command_response') + Validator.get_config('timeouts', 'status_response')
            diff = Time.parse(collector.messages.first.attributes['aSTS']) - clock
            diff = diff.round
            expect(diff.abs).to be <= max_diff,
                                "Timestamp of aggregated status is off by #{diff}s, should be within #{max_diff}s"
          end
        end
      end
    end

    # Verify command response timestamp after changing clock
    #
    # 1. Given the site is connected
    # 2. Send control command to set clock
    # 3. Send command to set functional position
    # 4. Compare set_clock and response timestamp
    # 5. Expect the difference to be within max_diff
    it 'is used for M0001 response timestamp', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        site.with_watchdog_disabled do # avoid time synchronization by disabling watchdogs
          with_clock_set site, clock do
            result = set_functional_position 'NormalControl'
            collector = result[:collector]
            max_diff = Validator.get_config('timeouts', 'command_response') * 2
            diff = Time.parse(collector.messages.first.attributes['cTS']) - clock
            diff = diff.round
            expect(diff.abs).to be <= max_diff,
                                "Timestamp of command response is off by #{diff}s, should be within #{max_diff}s"
          end
        end
      end
    end

    # Verify command response timestamp after changing clock
    #
    # 1. Given the site is connected
    # 2. Send control command to set clock
    # 3. Send command to set functional position
    # 4. Compare set_clock and response timestamp
    # 5. Expect the difference to be within max_diff
    it 'is used for M0104 response timestamp', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        site.with_watchdog_disabled do # avoid time synchronization by disabling watchdogs
          with_clock_set site, clock do
            result = set_functional_position 'NormalControl'
            collector = result[:collector]
            max_diff = Validator.get_config('timeouts', 'command_response')
            diff = Time.parse(collector.messages.first.attributes['cTS']) - clock
            diff = diff.round
            expect(diff.abs).to be <= max_diff,
                                "Timestamp of command response is off by #{diff}s, should be within #{max_diff}s"
          end
        end
      end
    end

    # Verify timestamp of alarm after changing clock
    # The test requires the device to be programmed so that
    # a A0302 alarm can be raise by activating a specific input, as
    # configuted in the test config.
    #
    # 1. Given the site is connected
    # 2. When we send a command to change the clock
    # 3. And we raise an alarm, by acticate an input
    # 4. Then we should receive an alarm
    # 5. And the alarm timestamp should be close to the time set the clock to

    it 'is used for alarm timestamp', :programming, sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        site.with_watchdog_disabled do # avoid time synchronization by disabling watchdogs
          with_clock_set site, clock do # set clock
            with_alarm_activated(task, site, 'A0302') do |alarm| # raise alarm, by activating input
              alarm_time = Time.parse(alarm.attributes['aTs'])
              max_diff = Validator.get_config('timeouts',
                                              'command_response') + Validator.get_config('timeouts', 'status_response')
              diff = alarm_time - clock
              expect(diff.round.abs).to be <= max_diff,
                                        "Timestamp of alarm is off by #{diff}s, should be within #{max_diff}s"
            end
          end
        end
      end
    end

    # Verify timestamp of watchdog after changing clock
    #
    # 1. Given the site is connected
    # 2. Send control command to setset_clock
    # 3. Wait for Watchdog
    # 4. Compare set_clock and alarm response timestamp
    # 5. Expect the difference to be within max_diff
    it 'is used for watchdog timestamp', sxl: '>=1.0.7' do |_example|
      Validator::SiteTester.connected do |task, _supervisor, site|
        prepare task, site
        site.with_watchdog_disabled do # avoid time synchronization by disabling watchdogs
          with_clock_set site, clock do
            log 'Checking watchdog timestamp'
            collector = RSMP::Collector.new site, task: task, type: 'Watchdog', num: 1,
                                                  timeout: Validator.get_config('timeouts', 'watchdog')
            collector.collect!
            max_diff = Validator.get_config('timeouts',
                                            'command_response') + Validator.get_config('timeouts', 'status_response')
            diff = Time.parse(collector.messages.first.attributes['wTs']) - clock
            diff = diff.round
            expect(diff.abs).to be <= max_diff,
                                "Timestamp of watchdog is off by #{diff}s, should be within #{max_diff}s"
          end
        end
      end
    end
  end
end
