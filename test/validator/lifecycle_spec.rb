require_relative '../../lib/rsmp/validator'

describe RSMP::Validator::Lifecycle do
  it 'waits for the local supervisor before starting an automatic site' do
    events = []
    tester = Object.new
    tester.define_singleton_method(:start_listener) { events << :supervisor_ready }
    auto_site = Object.new
    auto_site.define_singleton_method(:start) { events << :auto_site_started }

    previous_mode = RSMP::Validator.mode
    previous_auto_node = RSMP::Validator.auto_node
    previous_tester = RSMP::Validator::SiteTester.instance
    RSMP::Validator.mode = :site
    RSMP::Validator.auto_node = auto_site
    RSMP::Validator::SiteTester.instance = tester

    RSMP::Validator.send(:start_auto_node)

    expect(events).to be == %i[supervisor_ready auto_site_started]
  ensure
    RSMP::Validator.mode = previous_mode
    RSMP::Validator.auto_node = previous_auto_node
    RSMP::Validator::SiteTester.instance = previous_tester
  end
end
