# Writing Tests
Test are written as RSpec specifications.

Here's an example of a test that verifies that a Traffic Light Controllers responds with a NotAcknowledged if it receives an non-existing status request:

```ruby
RSpec.describe "Traffic Light Controller" do
  include StatusHelpers

  it 'responds with NotAck to invalid status request code' do |example|
    # wait for the site to be connected
    TestSite.connected do |task,supervisor,site|
      # write to the validator log file
      site.log "Requesting non-existing status S0000", level: :test
      
      # this is an RSpec expection block
      expect {
        # request a non-existing status
        status_list = convert_status_list( S0000:[:status] )
        site.request_status MAIN_COMPONENT, status_list, collect: {
          timeout: TIMEOUTS_CONFIG['command_response']
        },
        # normally we can't send S0000 because JSON Schema validation
        # will prevent it, but we can disable it for testing purposes
        validate: false
      }.to raise_error(RSMP::MessageRejected)   # expect an error
    end
  end
```

