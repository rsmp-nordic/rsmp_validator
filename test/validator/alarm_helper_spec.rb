require_relative '../../lib/rsmp/validator'

describe RSMP::Validator::Helpers::Alarms do
  let(:helper) { Object.new.extend(subject) }

  %w[3.1.5 3.2.0 3.3.0].each do |version|
    with "Core #{version}" do
      let(:proxy) { Struct.new(:core_version).new(version) }
      let(:matchers) { helper.send(:build_alarm_matchers, proxy) }

      it 'distinguishes active and inactive alarms' do
        _, active, inactive = matchers

        expect(active.match?('Active')).to be == true
        expect(active.match?('inActive')).to be == false
        expect(inactive.match?('inActive')).to be == true
        expect(inactive.match?('Active')).to be == false
      end

      it 'requires whole enum values, including for multiline input' do
        matchers.zip(%w[Issue Active inActive]).each do |matcher, value|
          expect(matcher.match?(value)).to be == true
          ["prefix#{value}", "#{value}suffix", "other\n#{value}", "#{value}\n"].each do |invalid|
            expect(matcher.match?(invalid)).to be == false
          end
        end
      end
    end
  end

  it 'still accepts older Core casing variants' do
    proxy = Struct.new(:core_version).new('3.1.5')
    issue, active, inactive = helper.send(:build_alarm_matchers, proxy)

    expect(issue.match?('issue')).to be == true
    expect(active.match?('active')).to be == true
    expect(active.match?('inactive')).to be == false
    expect(inactive.match?('inactive')).to be == true
  end
end
