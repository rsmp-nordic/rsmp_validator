# Writing Tests
Test are written as RSpec specifications.

Here's an example of a test that verifies that a Traffic Light Controllers responds with a NotAcknowledged if it receives an non-existing status request:

```ruby
RSpec.describe "Traffic Light Controller" do
  include StatusHelpers

  it 'responds with NotAck to invalid status request code' do |example|
    # wait for the site to be connected
    Validator::Site.connected do |task,supervisor,site|
      # write to the validator log file
      site.log "Requesting non-existing status S0000", level: :test
      
      # this is an RSpec expection block
      expect {
        # request a non-existing status
        status_list = convert_status_list( S0000:[:status] )
        site.request_status Validator.config['main_component'], status_list, collect: {
          timeout: Validator.config['timeouts']['command_response']
        },
        # normally we can't send S0000 because JSON Schema validation
        # will prevent it, but we can disable it for testing purposes
        validate: false
      }.to raise_error(RSMP::MessageRejected)   # expect an error
    end
  end
```

The [TestSite](Validator::Site.md) handles the connection to the site, and will pass a `RSMP::SiteProxy` object in the `site` argument, which can be used to communicate with the site. 

For example, you can request statuses ,subscribe to statuses and send commands. Many of the methods allow you to wait for response.

See the `rsmp`(https://github.com/rsmp-nordic/rsmp) for more documenation.

## Working with Exceptions and Timeouts
Timeouts an essential when testing external systems. When you send a command or request, you expect a respons within a certain amount of time. These timeouts must be defined in the test [configuration](configurin.md).

The `rsmp` gem will raise exceptions if a timeout is reached. Normally, you will not need to do any specific execption handling in your test code. You test will be aborted and RSpec will catch the error and report the error as failed.

