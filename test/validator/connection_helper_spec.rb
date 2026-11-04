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
