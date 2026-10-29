require_relative '../../lib/rsmp/validator'

describe RSMP::Validator::Helpers::Input do
  let(:patterns) { [] }
  let(:helper) do
    captured = patterns
    Object.new.extend(subject).tap do |object|
      object.define_singleton_method(:wait_for_status) do |_proxy, _description, statuses|
        captured << statuses.first.fetch('s')
      end
    end
  end
  let(:proxy) do
    tlc = Object.new
    tlc.define_singleton_method(:force_input!) { |**_options| true }
    tlc.define_singleton_method(:set_input!) { |**_options| true }
    Struct.new(:tlc).new(tlc)
  end

  it 'checks the forced input at the start of the string while allowing later bits' do
    helper.force_input_and_confirm(proxy, input: 2, value: 'True', within: 1)
    pattern = patterns.fetch(0)

    expect(pattern.match?('0101')).to be == true
    expect(pattern.match?('0001')).to be == false
    expect(pattern.match?("00\n0101")).to be == false
  end

  it 'checks both switched input states from the start of the string' do
    helper.switch_input(proxy, 2, within: 1)
    on, off = patterns

    expect(on.match?('0101')).to be == true
    expect(off.match?('0001')).to be == true
    expect(on.match?("00\n0101")).to be == false
    expect(off.match?("11\n0001")).to be == false
  end
end
