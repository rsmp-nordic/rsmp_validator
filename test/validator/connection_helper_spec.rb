require_relative '../../lib/rsmp/validator'

describe RSMP::Validator::Helpers::Connection do
  let(:helper) do
    Object.new.tap do |object|
      object.extend RSMP::Validator::Helpers::Connection
      object.instance_variable_set(:@__assertions__, assertions)
    end
  end
  let(:assertions) do
    Object.new.tap do |object|
      object.define_singleton_method(:assert) { |condition, message| recorded << [:assert, condition, message] }
      object.define_singleton_method(:error!) { |error| recorded << [:error, error] }
      object.define_singleton_method(:recorded) { @recorded ||= [] }
    end
  end

  {
    with_site: RSMP::Validator::SiteTester,
    with_supervisor: RSMP::Validator::SupervisorTester
  }.each do |method, tester|
    with method.to_s do
      before do
        @old_instance = tester.instance
        @old_config = RSMP::Validator.config
        RSMP::Validator.config = { 'timeouts' => {} }
        tester.instance = Object.new.tap do |instance|
          RSMP::Validator::Helpers::Connection::VALID_STATES.each do |state|
            instance.define_singleton_method(state) { |*_args, &block| block.call(nil, nil, :proxy) }
          end
        end
      end

      after do
        tester.instance = @old_instance
        RSMP::Validator.config = @old_config
      end

      RSMP::Validator::Helpers::Connection::VALID_STATES.each do |state|
        if method == :with_supervisor
          it "preserves the existing block arguments when #{state}" do
            args = nil
            helper.with_supervisor(state) { |*yielded| args = yielded }
            expect(args).to be == (state == :disconnected ? [] : [:proxy])
          end
        end

        it "records an operational failure and aborts when #{state}" do
          continued = false

          catch(:rsmp_validator_test_failure) do
            helper.public_send(method, state) do
              RSMP::Result.failure(:disconnected, message: 'connection closed').value!
            end
            continued = true
          end

          expect(continued).to be == false
          expect(assertions.recorded).to be == [[:assert, false, 'connection closed']]
        end

        it "reports missing configuration as an error and aborts when #{state}" do
          continued = false

          catch(:rsmp_validator_test_failure) do
            helper.public_send(method, state) do
              RSMP::Validator.get_config('timeouts', 'priority_completion')
            end
            continued = true
          end

          expect(continued).to be == false
          expect(assertions.recorded.size).to be == 1
          kind, error = assertions.recorded.first
          expect(kind).to be == :error
          expect(error).to be_a(RSMP::Validator::MissingConfiguration)
          expect(error.message).to be == 'Missing required test configuration: timeouts.priority_completion'
        end

        it "preserves unexpected exception details when #{state}" do
          catch(:rsmp_validator_test_failure) do
            helper.public_send(method, state) { raise 'validator bug' }
          end

          expect(assertions.recorded.size).to be == 1
          kind, error = assertions.recorded.first
          expect(kind).to be == :error
          expect(error).to be_a(RSMP::Validator::Helpers::Connection::UncaughtException)
          expect(error.message).to be == 'RuntimeError: validator bug'
          expect(error.backtrace.first).to be(:include?, __FILE__)
        end
      end

      if method == :with_supervisor
        it 'skips disabled or omitted scenarios before collecting or yielding' do
          helper.define_singleton_method(:skip) { |reason| throw :skip, reason }
          [{}, { 'test_scenarios' => false }].each do |config|
            RSMP::Validator.config = config
            reason = catch(:skip) do
              helper.with_scenario(nil, 'M0002.set_plan') { raise 'must not run test' }
            end
            expect(reason).to be == 'Supervisor test scenarios are disabled'
          end
        end

        it 'starts collection before yielding the scenario and stops it afterward' do
          RSMP::Validator.config['test_scenarios'] = true
          proxy = Object.new.extend(RSMP::Distributor)
          proxy.initialize_distributor
          helper.with_scenario(proxy, 'M0002.set_plan') do |scenario|
            expect(scenario).to be_a(RSMP::Validator::Scenario)
            expect(scenario.id).to be == 'M0002.set_plan'
            expect(scenario.proxy).to be == proxy
            expect(proxy.receivers.size).to be == 1
            expect(proxy.receivers.first).to be_a(RSMP::Queue)
          end
          expect(proxy.receivers).to be(:empty?)
        end

        it 'stops collection when a failed expectation aborts the scenario block' do
          RSMP::Validator.config['test_scenarios'] = true
          proxy = Object.new.extend(RSMP::Distributor)
          proxy.initialize_distributor
          catch(:rsmp_validator_test_failure) do
            helper.with_scenario(proxy, 'M0002.set_plan') { throw :rsmp_validator_test_failure }
          end
          expect(proxy.receivers).to be(:empty?)
        end

        it 'still skips enabled scenarios when Core or SXL requirements are not met' do
          RSMP::Validator.config['test_scenarios'] = true
          helper.define_singleton_method(:skip) { |reason| throw :skip, reason }
          mock(tester).replace(:isolated) { raise 'must not start connection' }
          mock(RSMP::Validator).replace(:sxl_matches?) { |_requirement| false }
          mock(RSMP::Validator).replace(:core_matches?) { |_requirement| false }

          %i[core sxl].each do |version|
            reason = catch(:skip) do
              helper.with_supervisor(:isolated, **{ version => '>=99.0.0' }) do |proxy|
                helper.with_scenario(proxy, 'M0002.set_plan') { raise 'must not run test' }
              end
            end
            expect(reason).to be == "requires #{version} >=99.0.0"
          end
        end
      end
    end
  end

  it 'records a validator error and stops the test body' do
    error = RuntimeError.new('validator bug')
    continued = false

    catch(:rsmp_validator_test_failure) do
      helper.send(:error_test, error)
      continued = true
    end

    expect(continued).to be == false
    expect(assertions.recorded).to be == [[:error, error]]
  end
end
