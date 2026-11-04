require_relative '../../lib/rsmp/validator'

describe RSMP::Validator::Helpers::Expectations do
  let(:assertions) { Sus::Assertions.default(output: Sus::Output::Null.new) }
  let(:helper) do
    Sus::Base.new(assertions).tap do |instance|
      instance.extend RSMP::Validator::Helpers::Expectations
      instance.extend RSMP::Validator::Helpers::Connection
    end
  end

  it 'continues and returns the expectation when it passes' do
    expectation = helper.expect_or_stop([])
    result = expectation.to(be_a(Array))

    expect(result).to be(:equal?, expectation)
    expect(assertions.passed?).to be == true
    expect(assertions.count).to be == 1
  end

  it 'records the normal diagnostic and stops before dependent code, running cleanup' do
    events = []
    catch(:rsmp_validator_test_failure) do
      helper.send(:run_test) do
        helper.expect_or_stop(nil).to be_a(Array)
        events << :dependent_code
      ensure
        events << :cleanup
      end
      events << :after_connection
    end

    ordinary = Sus::Assertions.default(output: Sus::Output::Null.new)
    Sus::Base.new(ordinary).expect(nil).to be_a(Array)
    expect(events).to be == [:cleanup]
    expect(assertions.failed.size).to be == 1
    expect(assertions.errored).to be(:empty?)
    expect(assertions.each_failure.first.message[:text]).to be == ordinary.each_failure.first.message[:text]
  end

  it 'continues after a passing negated expectation' do
    helper.expect_or_stop([]).not.to be_nil
    expect(assertions.passed?).to be == true
  end

  it 'stops after a failing negated expectation' do
    continued = false
    catch(:rsmp_validator_test_failure) do
      helper.expect_or_stop(nil).not.to be_nil
      continued = true
    end

    expect(continued).to be == false
    expect(assertions.failed.size).to be == 1
    expect(assertions.errored).to be(:empty?)
  end

  it 'ignores earlier failures when the current expectation passes' do
    helper.expect(false).to be == true
    helper.expect_or_stop([]).to be_a(Array)

    expect(assertions.failed.size).to be == 1
    expect(assertions.passed.size).to be == 1
  end

  it 'supports block expectations' do
    helper.expect_or_stop { raise ArgumentError, 'example' }.to raise_exception(ArgumentError)
    continued = false
    catch(:rsmp_validator_test_failure) do
      helper.expect_or_stop { :no_exception }.to raise_exception(ArgumentError)
      continued = true
    end

    expect(continued).to be == false
    expect(assertions.passed.size).to be == 1
    expect(assertions.failed.size).to be == 1
  end

  it 'stops on a failing chained predicate' do
    continued = false
    catch(:rsmp_validator_test_failure) do
      helper.expect_or_stop([]).to(be_a(Array)).and(be == [1])
      continued = true
    end

    expect(continued).to be == false
    expect(assertions.passed.size).to be == 1
    expect(assertions.failed.size).to be == 1
  end

  it 'records predicate errors once and stops' do
    continued = false
    catch(:rsmp_validator_test_failure) do
      helper.send(:run_test) do
        helper.expect_or_stop(nil).to be(:size)
        continued = true
      end
    end

    expect(continued).to be == false
    expect(assertions.errored.size).to be == 1
    expect(assertions.each_failure.first.message[:text]).to be(:include?, 'NoMethodError')
  end

  it 'rejects deferred expectations instead of silently continuing' do
    continued = false
    predicate = lambda do |scope, _subject|
      scope.defer { scope.assert(true) }
    end
    catch(:rsmp_validator_test_failure) do
      helper.expect_or_stop(nil).to(predicate)
      continued = true
    end
    assertions.resolve!

    expect(continued).to be == false
    expect(assertions.errored.size).to be == 1
    expect(assertions.each_failure.first.message[:text]).to be(:include?, 'ArgumentError')
    expect(assertions.each_failure.first.message[:text]).to be(:include?, 'immediate expectation')
  end

  it 'stops at the AsyncContext boundary and allows the next test to run' do
    previous_reactor = RSMP::Validator.reactor
    reactor = Async::Reactor.new
    RSMP::Validator.instance_variable_set(:@reactor, reactor)
    helper.extend RSMP::Validator::AsyncContext
    events = []

    helper.around do
      helper.expect_or_stop(nil).to be_a(Array)
      events << :dependent_code
    ensure
      events << :cleanup
    end
    helper.around { events << :next_test }

    expect(events).to be == %i[cleanup next_test]
    expect(assertions.failed.size).to be == 1
    expect(assertions.errored).to be(:empty?)
  ensure
    RSMP::Validator.instance_variable_set(:@reactor, previous_reactor)
    Fiber.set_scheduler(nil)
  end
end
