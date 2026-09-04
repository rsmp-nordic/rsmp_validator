require_relative '../../lib/rsmp/validator/helpers/connection'

describe RSMP::Validator::Helpers::Connection do
  let(:helper) do
    Object.new.tap do |object|
      object.extend subject
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

  it 'records an operational failure and stops the test body' do
    continued = false

    catch(:rsmp_validator_test_failure) do
      helper.send(:fail_test, 'connection closed')
      continued = true
    end

    expect(continued).to be == false
    expect(assertions.recorded).to be == [[:assert, false, 'connection closed']]
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
